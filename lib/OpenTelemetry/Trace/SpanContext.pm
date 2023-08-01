use Object::Pad ':experimental(init_expr)';
# ABSTRACT: The OpenTelemetry Span abstract interface

package OpenTelemetry::Trace::SpanContext;

our $VERSION = '0.001';

use OpenTelemetry::Trace::Common;
use OpenTelemetry::Propagator::TraceContext::TraceFlags;
use OpenTelemetry::Propagator::TraceContext::TraceState;

class OpenTelemetry::Trace::SpanContext {

    field $trace_flags :param :reader = undef;
    field $trace_state :param :reader = undef;
    field $trace_id    :param :reader = undef;
    field $span_id     :param :reader = undef;
    field $remote      :param :reader = 0;

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

    method hex_trace_id () { unpack 'H*', $trace_id }
    method hex_span_id  () { unpack 'H*', $span_id  }
}

use constant INVALID => OpenTelemetry::Trace::SpanContext->new(
    trace_id => OpenTelemetry::Trace::Common::INVALID_TRACE_ID,
    span_id  => OpenTelemetry::Trace::Common::INVALID_SPAN_ID,
);
