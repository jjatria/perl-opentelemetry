use Object::Pad;
# ABSTRACT: Propagate baggage using the W3C TraceContext format

package OpenTelemetry::Propagator::TraceContext;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category =>'OpenTelemetry' );

class OpenTelemetry::Propagator::TraceContext {
    use experimental qw( try isa );

    use URL::Encode qw( url_decode_utf8 url_encode_utf8 );
    use OpenTelemetry::Context::Propagation::TextMap;
    use OpenTelemetry::Trace::SpanContext;

    my $TRACE_PARENT_KEY = 'traceparent';
    my $TRACE_STATE_KEY  = 'tracestate';

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Context::Propagation::TextMap::SETTER
    ) {
        my $span_context = OpenTelemetry::Trace->span_from_context($context)->context;
        return unless $span_context->valid;

        my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent
            ->from_span_context($span_context);

        $setter->( $carrier, $TRACE_PARENT_KEY, $trace_parent->to_string );
        $setter->( $carrier, $TRACE_STATE_KEY,  $span_context->trace_state->to_string );

        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Context::Propagation::TextMap::GETTER
    ) {
        try {
            my $string = $getter->( $carrier, $TRACE_PARENT_KEY )
                or return $context;

            my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent->from_string($string);
            my $trace_state  = OpenTelemetry::Propagator::TraceContext::TraceState->from_string(
                $getter->( $carrier, $TRACE_STATE_KEY )
            );

            my $span_context = OpenTelemetry::Trace::SpanContext->new(
                trace_id    => $trace_parent->trace_id,
                span_id     => $trace_parent->span_id,
                trace_flags => $trace_parent->flags,
                trace_state => $trace_state,
                remote      => 1,
            );

            my $span = OpenTelemetry::Trace->non_recording_span( $span_context );

            return OpenTelemetry::Trace->context_with_span( $span );
        }
        catch ($e) {
            die $e unless $e isa OpenTelemetry::X;
            $logger->warn($e);
            return $context;
        }
    }

    method keys () { ( $TRACE_PARENT_KEY, $TRACE_STATE_KEY ) }
}
