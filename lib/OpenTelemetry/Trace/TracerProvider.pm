use Object::Pad;
# ABSTRACT: Provides access to OpenTelemetry Tracers

package OpenTelemetry::Trace::TracerProvider;

our $VERSION = '0.029';

class OpenTelemetry::Trace::TracerProvider {
    use OpenTelemetry::Trace::Tracer;

    field $tracer;

    method tracer ( %args ) {
        $tracer //= OpenTelemetry::Trace::Tracer->new;
    }
}
