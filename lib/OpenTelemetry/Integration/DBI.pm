package OpenTelemetry::Integration::DBI;
# ABSTRACT: OpenTelemetry integration for DBI

our $VERSION = '0.001';

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
                driver => lc $dbh->{Driver}{Name},
                user   =>    $dbh->{Username},
            );

            ( $meta{host} ) = $name =~ /host=([^;]+)/;
            ( $meta{port} ) = $name =~ /port=([0-9]+)/;

            # Driver-specific metadata available before call
            $meta{driver_specific} = do {
                my %data;

                if ( $meta{driver} eq 'mysql' ) {
                    %data = (
                        'network.transport' => 'IP.TCP'
                    );
                }

                \%data;
            };

            \%meta;
        };

        $statement = $statement =~ s/^\s+|\s+$//gr =~ s/\s+/ /gr;

        my $span = OpenTelemetry->tracer_provider->tracer->create_span(
            name       => substr($statement, 0, 100) =~ s/\s+$//r,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                'db.connection_string' => $name,
                'db.statement'         => $statement,
                'db.system'            => $info->{driver},
                'db.user'              => $info->{user},
                'server.address'       => $info->{host},
                'server.port'          => $info->{port},
                %{ $info->{driver_specific} // {} },
            },
        );

        dynamically OpenTelemetry::Context->current
            = OpenTelemetry::Trace->context_with_span($span);

        try {
            return $handle->$orig(@args);
        }
        catch ( $error ) {
            $span->record_exception($error);
            $span->set_status( SPAN_STATUS_ERROR, $error );
            die $error;
        }
        finally {
            if ( $handle->err ) {
                $span->set_status( SPAN_STATUS_ERROR, $handle->errstr );
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

__END__

=encoding utf8

=head1 NAME

OpenTelemetry::Integration::DBI - OpenTelemetry integration for DBI

=head1 SYNOPSIS

    use OpenTelemetry::Integration 'DBI';
    my $dbh = DBI->connect(...);
    my $result = $dbh->selectall_hashref($statement);

=head1 DESCRIPTION

See L<OpenTelemetry::Integration> for more details.

Since this is a core module, it's included in the L<OpenTelemetry> core
distribution as well.

=head1 COPYRIGHT

...
