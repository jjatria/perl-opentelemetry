use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A link to an OpenTelemetry span

package OpenTelemetry::Trace::Link;

our $VERSION = '0.034';

class OpenTelemetry::Trace::Link :does(OpenTelemetry::Attributes) {
    use OpenTelemetry::X;

    use isa 'OpenTelemetry::Trace::SpanContext';

    field $context :param :reader;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Required parameter 'context' must be a span context"
        ) unless isa_OpenTelemetry_Trace_SpanContext $context;
    }
}
