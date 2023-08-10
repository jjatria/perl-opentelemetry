package OpenTelemetry::Integration::DBI;
# ABSTRACT: OpenTelemetry integration for DBI

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';
use feature 'state';

use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Defer;
use OpenTelemetry::Constants qw( SPAN_KIND_CLIENT SPAN_STATUS_ERROR SPAN_STATUS_OK );
use OpenTelemetry;

use parent 'OpenTelemetry::Integration';

sub dependencies { 'DBI' }

my ( $original, $loaded );
sub uninstall ( $class ) {
    return unless $original;
    no strict 'refs';
    no warnings 'redefine';
    delete $Class::Method::Modifiers::MODIFIER_CACHE{'DBI::st'}{execute};
    *{'DBI::st::execute'} = $original;
    undef $loaded;
    return;
}

sub install ( $class, %options ) {
    return if $loaded;
    return unless Class::Inspector->loaded('DBI');

    $original = \&DBI::st::execute;
    install_modifier 'DBI::st' => around => execute => sub {
        my ( $code, $sth, @bind ) = @_;

        my $dbh  = $sth->{Database};
        my $name = $dbh->{Name};

        state %meta;

        my $info = $meta{$name} //= do {
            my %meta = (
                driver => lc $dbh->{Driver}{Name},
                user   =>    $dbh->{Username},
            );

            ( $meta{host} ) = $name =~ /host=([^;]+)/;
            ( $meta{port} ) = $name =~ /port=([0-9]+)/;

            \%meta;
        };

        # Driver-specific metadata available before call
        my %driver;
        if ( $info->{driver} eq 'mysql' ) {
            $driver{'network.transport'} = 'IP.TCP';
        }

        my $statement = $sth->{Statement} =~ s/^\s+|\s+$//gr =~ s/\s+/ /gr;

        my $tracer = OpenTelemetry->tracer_provider->tracer;

        my $span = $tracer->create_span(
            name       => substr($statement, 0, 100) =~ s/\s+$//r,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                'db.connection_string' => $name,
                'db.statement'         => $statement,
                'db.system'            => $info->{driver},
                'db.user'              => $info->{user},
                'server.address'       => $info->{host},
                'server.port'          => $info->{port},
                %driver,
            },
        );

        defer { $span->end }

        my $return = $sth->$code(@bind);

        if ( ! defined $return || $sth->err ) {
            $span->set_status( SPAN_STATUS_ERROR, $sth->errstr );
        }
        else {
            $span->set_status( SPAN_STATUS_OK );
        }

        # Driver-specific metadata available after call
        if ( $info->{driver} eq 'mysql' ) {
            $span->set_attribute(
                'db.sql.table' => ${ $sth->{mysql_table} // [] }[0],
            );
        }

        return $return;
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
