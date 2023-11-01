package OpenTelemetry::Integration;
# ABSTRACT: Top-level interface for OpenTelemetry integrations

our $VERSION = '0.012';

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
