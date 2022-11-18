use Object::Pad;
# ABSTRACT: A link to an OpenTelemetry span

package OpenTelemetry::Trace::Link;

our $VERSION = '0.001';

class OpenTelemetry::Trace::Link {
    use experimental 'isa';

    use OpenTelemetry::X;

    has $context     :param :reader;
    has $attributes  :param :reader = undef;

    ADJUST {
        $attributes //= {};

        die OpenTelemetry::X->create(
            Invalid => "Required parameter 'context' must be a span context"
        ) unless $context isa OpenTelemetry::Trace::SpanContext;
    }
}
