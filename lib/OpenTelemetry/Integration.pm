package OpenTelemetry::Integration;
# ABSTRACT: Top-level interface for OpenTelemetry integrations

our $VERSION = '0.001';

use experimental 'signatures';

use Feature::Compat::Try;
use List::Util 'uniqstr';
use Module::Load ();
use Module::Pluggable search_path => ['OpenTelemetry::Integration'];
use Ref::Util 'is_hashref';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

# To be overriden by integrations
sub dependencies { }
sub uninstall { } # experimental

my @installed;
sub import ( $class, @args ) {
    return unless @args;

    my $all = $args[0] =~ /^[:-]all$/ && shift @args;

    my %configuration;
    while ( my $key = shift @args ) {
        my $options = is_hashref $args[0] ? shift @args : {};
        $configuration{ __PACKAGE__ . '::' . $key } = $options;
    }

    if ($all) {
        $configuration{$_} //= {} for $class->plugins
    }

    for my $package ( keys %configuration ) {
        try {
            $logger->tracef('Loading %s', $package);

            Module::Load::load($package);

            # We only load dependencies if we are not loading every module
            unless ($all) {
                Module::Load::load($_) for $package->dependencies;
            }

            my $ok = $package->install( %{ $configuration{ $package } } );

            if ($ok) {
                push @installed, $package;
            }
            else {
                $logger->tracef("$package did not install itself");
            }

        } catch ($e) {
            # Just a warning, if we're loading everything then
            # we shouldn't cause chaos just because something
            # doesn't happen to be available.
            $logger->warnf('Unable to load %s: %s', $package, $e);
        }
    }
}

sub unimport ( $class, @args ) {
    @args = @installed unless @args;
    $_->uninstall for @args;
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

OpenTelemetry::Integration - Top-level interface for OpenTelemetry integrations

=head1 SYNOPSIS

    # Load integrations for specific modules
    use OpenTelemetry::Integration qw( HTTP::Tiny DBI );

    # Some integrations can take additional options
    use OpenTelemetry::Integration 'HTTP::Tiny' => \%options;

    # Load every available integration
    use OpenTelemetry::Integration -all;

=head1 DESCRIPTION

This is the base class for handling tracing integration with other CPAN
modules.

It provides functionality for loading available integrations
via the import list on a C<use> statement:

=over 4

=item *

with C<-all>, all available OpenTelemetry integrations will be loaded,
if the module the integration is for has already been loaded

=item *

with a specific list of modules, they will be loaded (even if they haven't
been before) and integrations for them will be applied if available

=back

This means that you can expect L<HTTP::Tiny> to be traced if you have the
L<OpenTelemetry::Integration::HTTP::Tiny> module installed and you do this:

    use OpenTelemetry::Integration 'HTTP::Tiny';

or this:

    use HTTP::Tiny;
    use OpenTelemetry::Integration -all;

but it will B<not> be traced if you do this:

    use OpenTelemetry::Integration -all;
    use HTTP::Tiny;

The rationale behind this apparently inconsistent behaviour is that, with a
large install, C<:all> might load unexpected integrations. This behaviour
allows you instead to add this line after your module imports, and any
functionality that is actively being used in the code (for which an
integration module is available) would gain tracing.

=head2 Configuring integrations

=head1 WRITING INTEGRATIONS

Additional integrations can be written and used as long as they are in the
the OpenTelemetry::Integration namespace. They should subclass this module
(OpenTelemetry::Integration) and should implement an C<install> class method
as described in detail below. Other methods described in this section are
optional, but can be used to provide additional features.

=head2 install

    $bool = $class->install(%configuration);

Installs the integration. Will be called with a (possibly empty) list of
key/value pairs with configuration options, and is expected to return a
true value if the integration was installed, or false otherwise.

An example implementation of this method might look like the following:

    package OpenTelemetry::Integration::Foo::Bar;

    use experimental 'signatures';
    use Class::Inspector;
    use Class::Method::Modifiers 'install_modifier';

    my $loaded;
    sub install ( $class, %config ) {
        return if $loaded++;
        return unless Class::Inspector->loaded('Foo::Bar');

        install_modifier 'Foo::Bar' => around => reticulate_splines => sub {
            my ( $orig, $self, @args ) = @_;
            ...
            my $value = $self->$orig(@args);
            ...
            return $value;
        };

        return 1;
    }

=head2 dependencies

    @package_names = $class->dependencies;

Should return the names of the packages that should be loaded to install
this integration. This method will be called in list context when loading
dependencies automatically (ie. not when using the C<all> flag) to load
the dependencies before calling L<install|/install>.

=head1 COPYRIGHT

...
