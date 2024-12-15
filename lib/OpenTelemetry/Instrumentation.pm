package OpenTelemetry::Instrumentation;
# ABSTRACT: Top-level interface for OpenTelemetry instrumentations

our $VERSION = '0.026';

use strict;
use warnings;
use experimental 'signatures';

use Feature::Compat::Try;
use List::Util 'uniqstr';
use Module::Runtime ();
use Module::Pluggable search_path => [qw(
    OpenTelemetry::Instrumentation
    OpenTelemetry::Integration
)];
use Ref::Util 'is_hashref';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

# To be overriden by instrumentations
sub dependencies { }
sub uninstall { } # experimental

my sub module_exists ($module) {
    my $file = Module::Runtime::module_notional_filename $module;
    for (@INC) {
        return 1 if -e "$_/$file";
    }
    return 0;
}

my @installed;
sub import ( $class, @args ) {
    return unless @args;

    my $all = $args[0] =~ /^[:-]all$/ && shift @args;

    # Inlined from OpenTelemetry::Common to read Perl-specific config
    my $legacy_support = $ENV{OTEL_PERL_USE_LEGACY_INSTRUMENTATIONS} // 1;
    $legacy_support
        = $legacy_support =~ /^true$/i  ? 1
        : $legacy_support =~ /^false$/i ? 0
        : $legacy_support;

    my %configuration;
    while ( my $key = shift @args ) {
        my $options = is_hashref $args[0] ? shift @args : {};

        # Legacy namespace support. If we are loading an integration
        # by name which does not exist in INC in the new namespace,
        # but does exist in the legacy namespace, we use the legacy
        # name instead.
        my $module = __PACKAGE__ . '::' . $key;
        if ( $legacy_support && !module_exists($module) ) {
            my $legacy = $module =~ s/^OpenTelemetry::Instrumentation/OpenTelemetry::Integration/r;
            $module = $legacy if module_exists($legacy);
        }

        $configuration{$module} = $options;
    }

    if ($all) {
        for my $plugin ($class->plugins) {
            if ( $plugin =~ /^OpenTelemetry::Instrumentation/ ) {
                $configuration{$plugin} //= {};
                next;
            }

            next unless $legacy_support;

            my $canonical = $plugin =~ s/^OpenTelemetry::Integration/OpenTelemetry::Instrumentation/r;
            next if $configuration{$canonical};

            $configuration{$plugin} //= {};
        }
    }

    for my $package ( keys %configuration ) {
        try {
            $logger->tracef('Loading %s', $package);

            Module::Runtime::require_module($package);

            # We only load dependencies if we are not loading every module
            unless ($all) {
                Module::Runtime::require_module($_) for $package->dependencies;
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
