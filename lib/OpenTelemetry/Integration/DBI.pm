package OpenTelemetry::Integration::DBI;
# ABSTRACT: OpenTelemetry integration for DBI

our $VERSION = '0.017';

use strict;
use warnings;
use experimental 'signatures';
use feature 'state';

use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Try;
use OpenTelemetry::Constants qw( SPAN_KIND_CLIENT SPAN_STATUS_ERROR SPAN_STATUS_OK );
use OpenTelemetry::Context;
use OpenTelemetry::Trace;
use OpenTelemetry;
use Syntax::Keyword::Dynamically;

use parent 'OpenTelemetry::Integration';

sub dependencies { 'DBI' }

my ( $EXECUTE, $DO, $loaded );
sub uninstall ( $class ) {
    return unless $loaded;
    no strict 'refs';
    no warnings 'redefine';
    delete $Class::Method::Modifiers::MODIFIER_CACHE{'DBI::st'}{execute};
    *{'DBI::st::execute'} = $EXECUTE;
    *{'DBI::db::do'}      = $DO;
    undef $loaded;
    return;
}

sub install ( $class, %options ) {
    return if $loaded;
    return unless Class::Inspector->loaded('DBI');

    my $wrapper = sub ( $dbh, $statement, $orig, $handle, @args ) {
        state %meta;

        my $name = $dbh->{Name};

        my $info = $meta{$name} //= do {
            my %meta = (
                'db.system' => lc $dbh->{Driver}{Name},
            );

            $meta{'db.user'}        = $dbh->{Username} if $dbh->{Username};
            $meta{'server.address'} = $1               if $name =~ /host=([^;]+)/;
            $meta{'server.port'}    = $1               if $name =~ /port=([0-9]+)/;

            # Driver-specific metadata available before call
            if ( $meta{'db.system'} eq 'mysql' ) {
                $meta{'network.transport'} = 'IP.TCP';
            }

            \%meta;
        };

        $statement = $statement =~ s/^\s+|\s+$//gr =~ s/\s+/ /gr;

        my $span = OpenTelemetry->tracer_provider->tracer->create_span(
            name       => substr($statement, 0, 100) =~ s/\s+$//r,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                'db.connection_string' => $name,
                'db.statement'         => $statement,
                %$info,
            },
        );

        dynamically OpenTelemetry::Context->current
            = OpenTelemetry::Trace->context_with_span($span);

        try {
            return $handle->$orig(@args);
        }
        catch ( $error ) {
            my ($description) = split /\n/, $error =~ s/^\s+|\s+$//gr, 2;
            $description =~ s/ at \S+ line \d+\.$//a;

            $span->record_exception($error);
            $span->set_status( SPAN_STATUS_ERROR, $description );

            die $error;
        }
        finally {
            if ( $handle->err ) {
                my $error = $handle->errstr =~ s/^\s+|\s+$//gr;

                my ($description) = split /\n/, $error, 2;
                $description =~ s/ at \S+ line \d+\.$//a;

                $span->set_status( SPAN_STATUS_ERROR, $description );
            }
            else {
                $span->set_status( SPAN_STATUS_OK );
            }

            $span->end;
        }
    };

    $EXECUTE = \&DBI::st::execute;
    install_modifier 'DBI::st' => around => execute => sub {
        my ( undef, $sth ) = @_;
        unshift @_, $sth->{Database}, $sth->{Statement};
        goto $wrapper;
    };

    $DO = \&DBI::st::execute;
    install_modifier 'DBI::db' => around => do => sub {
        my ( undef, $dbh, $sql ) = @_;
        unshift @_, $dbh, $sql;
        goto $wrapper;
    };

    return $loaded = 1;
}

1;
