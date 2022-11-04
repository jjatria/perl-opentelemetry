use Object::Pad;
# ABSTRACT: A context class for OpenTelemetry

package OpenTelemetry::Trace::Tracer::Proxy;

our $VERSION = '0.001';

class OpenTelemetry::Trace::Tracer::Proxy isa OpenTelemetry::Trace::Tracer {
    use mro;

    has $delegate :reader;

    method create_span ( %args ) {
        return $self->next::method( %args ) unless $delegate;
        $delegate->create_span( %args );
    }
}
