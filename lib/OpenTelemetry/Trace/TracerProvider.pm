use Object::Pad;
# ABSTRACT: Provides access to OpenTelemetry Tracers

package OpenTelemetry::Trace::TracerProvider;

our $VERSION = '0.001';

class OpenTelemetry::Trace::TracerProvider {
    use OpenTelemetry::Trace::Tracer;

    field $tracer;

    method tracer ( %args ) {
        $tracer //= OpenTelemetry::Trace::Tracer->new;
    }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace::TracerProvider - Provides access to OpenTelemetry Tracers

=head1 SYNOPSIS

    use OpenTelemetry;

    # Read the globally set provider
    my $provider = OpenTelemetry->tracer_provider;
    my $tracer   = $provider->tracer;
    my $span     = $tracer->create_span( name => 'My span' );

    # Set a global tracer provider
    OpenTelemetry->tracer_provider( $another_provider );

=head1 DESCRIPTION

As implied by its name, the tracer provider is responsible for providing
access to a usable instance of L<OpenTelemetry::Trace::Tracer>, which can in
turn be used to create L<OpenTelemetry::Trace::Span> instances to mark the
scope of an operation.

The provider implemented in this package returns an instance of
L<OpenTelemetry::Trace::Tracer> which is cached internally. This behaviour
can be modified by inheriting from this class and providing a different
implementation of the L<tracer|/tracer> method described below. See
L<OpenTelemetry|OpenTelemetry/tracer_provider> for a way to set this
modified version as a globall yavailable tracer provider.

=head1 METHODS

=head2 new

    $provider = OpenTelemetry::Trace::TracerProvider->new

Creates a new instance of the tracer provider.

=head2 tracer

    $tracer = $trace_provider->tracer( %args )

Takes a set of named parameters, and returns the tracer provided by this
provider.

The code implemented in this package ignores all arguments and returns a
L<OpenTelemetry::Trace::Tracer>, but subclasses are free to modify this.

Callers of this method should B<not> cache this tracer, since the tracer
provider might have changed since the last time the tracer was created.
If creating the tracer is expensive, then it's the tracer provider's
responsibility to cache it.

=head1 COPYRIGHT AND LICENSE

...
