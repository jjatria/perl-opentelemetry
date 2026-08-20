package OpenTelemetry::Instrumentation::DBI;
# ABSTRACT: OpenTelemetry instrumentation for DBI

our $VERSION = '0.036';

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
use Scalar::Util 'blessed';
use Syntax::Keyword::Dynamically;

use parent 'OpenTelemetry::Instrumentation';

sub dependencies { 'DBI' }

my ( $CONNECT, $EXECUTE, $DO, $loaded );
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

    my $wrapper = sub ( $opts, $orig, $invokant, @args ) {
        # from https://opentelemetry.io/docs/specs/semconv/registry/attributes/db/#db-system-name
        state %system_name = (
            Pg          => 'postgresql',
            PgAsync     => 'postgresql',
            mysql       => 'mysql',
            Oracle      => 'oracle.db',
            SQLite      => 'sqlite',
            MariaDB     => 'mariadb',
            Cassandra   => 'cassandra',
            Sybase      => 'microsoft.sql_server',
        );

        state %meta;

        my $name = $opts->{dbh}{name} // '';

        my $info = $meta{$name} //= do {
            my %meta;

            if ( my $system_name = $system_name{ $opts->{dbh}{driver} // '' } ) {
                $meta{'db.system.name'} = $system_name;
            }

            $meta{'server.address'} = $1 if $name =~ /host=([^;]+)/;
            $meta{'server.port'}    = $1 if $name =~ /port=([0-9]+)/;

            # Driver-specific metadata available before call
            if ( ( $meta{'db.system.name'} // '' ) eq 'mysql' ) {
                $meta{'network.transport'} = 'IP.TCP';
            }

            \%meta;
        };

        for ( $opts->{statement} ) {
            last unless $_;
            s/^\s+|\s+$//g;
            s/\s+/ /g;
        }

        $opts->{name} //= substr( $opts->{statement}, 0, 100 ) =~ s/\s+$//r;

        my $span = OpenTelemetry->tracer_provider->tracer->create_span(
            name       => $opts->{name},
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                $opts->{statement} ? ( 'db.statement' => $opts->{statement} ) : (),
                %$info,
            },
        );

        dynamically OpenTelemetry::Context->current
            = OpenTelemetry::Trace->context_with_span($span);

        my $errstr;
        try {
            if ( $opts->{name} eq 'connect' ) {
                my $dbh = $invokant->$orig(@args);
                $errstr = $DBI::errstr unless $dbh;
                return $dbh;
            }

            return $invokant->$orig(@args);
        }
        catch ( $error ) {
            my ($description) = split /\n/, $error =~ s/^\s+|\s+$//gr, 2;
            $description =~ s/ at \S+ line \d+\.$//a;

            $span->record_exception($error);
            $span->set_status( SPAN_STATUS_ERROR, $description );

            die $error;
        }
        finally {
            $errstr ||= $invokant->errstr
                if blessed $invokant && $invokant->err;

            if ( $errstr ) {
                $errstr =~ s/^\s+|\s+$//g;

                my ($description) = split /\n/, $errstr, 2;
                $description =~ s/ at \S+ line \d+\.$//a;

                $span->set_status( SPAN_STATUS_ERROR, $description );
            }
            else {
                $span->set_status( SPAN_STATUS_OK );
            }

            $span->end;
        }
    };

    $CONNECT = \&DBI::connect;
    install_modifier 'DBI' => around => connect => sub {
        my ( undef, undef, $dsn ) = @_;

        # this might fail and return an empty list which is ok, in that case keep
        # continuing and don't populate the span attributes
        my ( undef, $driver, undef, undef, $driver_dsn ) = DBI->parse_dsn($dsn);

        unshift @_, {
            name => 'connect',
            dbh => {
                driver => $driver,
                name   => $driver_dsn,
            },
        };

        goto $wrapper;
    };

    $EXECUTE = \&DBI::st::execute;
    install_modifier 'DBI::st' => around => execute => sub {
        my ( undef, $sth ) = @_;
        unshift @_, {
            dbh => {
                driver => $sth->{Database}{Driver}{Name},
                name   => $sth->{Database}{Name},
            },
            statement => $sth->{Statement},
        };

        goto $wrapper;
    };

    $DO = \&DBI::st::do;
    install_modifier 'DBI::db' => around => do => sub {
        my ( undef, $dbh, $sql ) = @_;
        unshift @_, {
            dbh => {
                driver => $dbh->{Driver}{Name},
                name   => $dbh->{Name},
            },
            statement => $sql,
        };

        goto $wrapper;
    };

    return $loaded = 1;
}

1;
