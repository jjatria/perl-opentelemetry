use Object::Pad;
# ABSTRACT: The OpenTelemetry Span abstract interface

package OpenTelemetry::Trace::SpanContext;

our $VERSION = '0.001';

use OpenTelemetry::Trace::Common;
    use OpenTelemetry::Propagator::TraceContext::TraceFlags;
    use OpenTelemetry::Propagator::TraceContext::TraceState;

class OpenTelemetry::Trace::SpanContext {

    has $trace_flags :param :reader = undef;
    has $trace_state :param :reader = undef;
    has $trace_id    :param :reader = undef;
    has $span_id     :param :reader = undef;
    has $remote      :param :reader = 0;

    BUILD {
        $trace_flags //= OpenTelemetry::Propagator::TraceContext::TraceFlags->new;
        $trace_state //= OpenTelemetry::Propagator::TraceContext::TraceState->new;
        $trace_id    //= OpenTelemetry::Trace::Common->generate_trace_id;
        $span_id     //= OpenTelemetry::Trace::Common->generate_span_id;
    }

    method valid () {
           $trace_id && $trace_id ne OpenTelemetry::Trace::Common::INVALID_TRACE_ID
        && $span_id  && $span_id  ne OpenTelemetry::Trace::Common::INVALID_SPAN_ID;
    }
}

use constant INVALID => OpenTelemetry::Trace::SpanContext->new(
    trace_id => OpenTelemetry::Trace::Common::INVALID_TRACE_ID,
    span_id  => OpenTelemetry::Trace::Common::INVALID_SPAN_ID,
);
