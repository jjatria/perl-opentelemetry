use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A link to an OpenTelemetry span

package OpenTelemetry::Trace::Link;

our $VERSION = '0.023';

class OpenTelemetry::Trace::Link :does(OpenTelemetry::Attributes) {
    use experimental 'isa';

    use OpenTelemetry::X;

    field $context :param :reader;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Required parameter 'context' must be a span context"
        ) unless $context isa OpenTelemetry::Trace::SpanContext;
    }
}
