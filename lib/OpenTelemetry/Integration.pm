package OpenTelemetry::Integration;
# ABSTRACT: Top-level interface for OpenTelemetry integrations

our $VERSION = '0.001';

use experimental qw( try signatures );

use Syntax::Keyword::Try;
use Module::Pluggable search_path => ['OpenTelemetry::Integration'];
use Module::Load ();
use List::Util 'uniqstr';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

sub import ( $class, @args ) {
    return unless @args;

    # If we have an explicit list, then we load
    # dependencies - this is turned off by :all tag
    my $load_deps = 1;

    my @modules;
    for my $target ( grep $_, @args ) {
        # Try to load *all* available integrations
        if ( $target eq ':all' ) {
            push @modules, $class->plugins;
            $load_deps = 0;
            last;
        }

        push @modules, __PACKAGE__ . '::' . $target;
    }

    for my $module ( uniqstr @modules ) {
        try {
            $logger->tracef('Loading %s', $module);
            Module::Load::load($module);
            $module->load($load_deps);
        } catch ($e) {
            # Just a warning, if we're loading everything then
            # we shouldn't cause chaos just because something
            # doesn't happen to be available.
            $logger->warnf('Unable to load %s: %s', $module, $e);
        }
    }
}

1;

__END__

=encoding utf8

=head1 NAME

OpenTelemetry::Integration - Top-level interface for OpenTelemetry integrations

=head1 SYNOPSIS

    # Load integrations specific modules
    use OpenTelemetry::Integration qw( HTTP::Tiny DBI );

    # Load  every available integration
    use OpenTelemetry::Integration ':all';

=head1 DESCRIPTION

This is the base class for handling tracing integration with other CPAN
modules.

It provides functionality for loading available integrations
via the import list on a C<use> statement:

=over 4

=item *

with C<:all>, all available OpenTelemetry integrations will be loaded,
if the module the integration is for has already been loaded

=item *

with a specific list of modules, they will be loaded (even if they haven't
been before) and integrations for them will be applied if available

=back

This means that you can expect L<HTTP::Tiny> to be traced if you have the
L<OpenTelemetry::Integration::HTTP::Tiny> module installed and you do this:

    use OpenTracing::Integration 'HTTP::Tiny';

or this:

    use HTTP::Tiny;
    use OpenTracing::Integration ':all';

but it will B<not> be traced if you do this:

    use OpenTracing::Integration ':all';
    use HTTP::Tiny;

The rationale behind this apparently inconsistent behaviour is that, with a
large install, C<:all> might load unexpected integrations. This behaviour
allows you instead to add this line after your module imports, and any
functionality that is actively being used in the code (for which an
integration module is available) would gain tracing.

=head1 COPYRIGHT

...
