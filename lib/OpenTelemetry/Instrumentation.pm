package OpenTelemetry::Instrumentation;
# ABSTRACT: Top-level interface for OpenTelemetry instrumentations

our $VERSION = '0.032';

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
use Scalar::Util 'blessed';
use Ref::Util qw( is_coderef is_hashref is_arrayref );
use OpenTelemetry::Common ();

my $logger = OpenTelemetry::Common::internal_logger;

# To be overriden by instrumentations
sub dependencies { }
sub uninstall { } # experimental

my %REGISTRY;
my sub find_instrumentations {
    my $class = shift;
    return if %REGISTRY; # Runs once and caches results

    # Inlined from OpenTelemetry::Common to read Perl-specific config
    my $legacy_support = $ENV{OTEL_PERL_USE_LEGACY_INSTRUMENTATIONS} // 1;
    $legacy_support
        = $legacy_support =~ /^true$/i  ? 1
        : $legacy_support =~ /^false$/i ? 0
        : $legacy_support;

    # We sort the plugins so that we prefer the Instrumentation namespace
    for ( sort $class->plugins ) {
        last if /^OpenTelemetry::Integration::/ && !$legacy_support;
        $REGISTRY{ s/^OpenTelemetry::(?:Instrumentation|Integration):://r } ||= $_
    }

    return;
}

sub for_package ($class, $package, @) {
    find_instrumentations($class);
    $REGISTRY{$package // ''};
}

my @installed;
sub import ( $class, @args ) {
    return unless @args;

    my $all = $args[0] =~ /^[:-]all$/ && shift @args;

    my %configuration;
    while ( my $key = shift @args ) {
        my $options = is_hashref($args[0]) || is_arrayref($args[0])
            ? shift @args : {};

        # Legacy namespace support. If we are loading an integration
        # by name which does not exist in INC in the new namespace,
        # but does exist in the legacy namespace, we use the legacy
        # name instead.
        my $instrumentation = $class->for_package($key);

        unless ( $instrumentation ) {
            $logger->warn(
                "Unable to load OpenTelemetry instrumentation for $key: Can't locate any suitable module in \@INC (you may need to install OpenTelemetry::Instrumentation::$key) (\@INC entries checked: @INC)",
            );
            next;
        }

        $configuration{$instrumentation} = $options;
    }

    if ($all) {
        find_instrumentations($class);
        $configuration{$_} //= {} for values %REGISTRY;
    }

    for my $package ( keys %configuration ) {
        try {
            $logger->tracef('Loading %s', $package);

            Module::Runtime::require_module($package);

            # We only load dependencies if we are not loading every module
            unless ($all) {
                Module::Runtime::require_module($_) for $package->dependencies;
            }

            my $config = $configuration{ $package };
            my $ok = $package->install( is_hashref $config ? %$config : @$config );

            if ($ok) {
                push @installed, $package;
            }
            else {
                $logger->tracef("$package did not install itself");
            }

        }
        catch ($e) {
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
