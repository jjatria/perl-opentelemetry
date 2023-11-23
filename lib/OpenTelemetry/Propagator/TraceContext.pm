use Object::Pad;
# ABSTRACT: Propagate context using the W3C TraceContext format

package OpenTelemetry::Propagator::TraceContext;

our $VERSION = '0.019';

class OpenTelemetry::Propagator::TraceContext :does(OpenTelemetry::Propagator) {
    use experimental 'isa';

    use Feature::Compat::Try;
    use URL::Encode qw( url_decode_utf8 url_encode_utf8 );

    use OpenTelemetry;
    use OpenTelemetry::Propagator::TextMap;
    use OpenTelemetry::Propagator::TraceContext::TraceParent;
    use OpenTelemetry::Propagator::TraceContext::TraceState;
    use OpenTelemetry::Trace::SpanContext;
    use OpenTelemetry::Trace;

    my $TRACE_PARENT_KEY = 'traceparent';
    my $TRACE_STATE_KEY  = 'tracestate';

    use Log::Any;
    my $logger = Log::Any->get_logger( category =>'OpenTelemetry' );

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Propagator::TextMap::SETTER
    ) {
        try {
            my $span_context = OpenTelemetry::Trace
                ->span_from_context($context)
                ->context;

            return $self unless $span_context->valid;

            my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent
                ->from_span_context($span_context);

            $setter->( $carrier, $TRACE_PARENT_KEY, $trace_parent->to_string );
            $setter->( $carrier, $TRACE_STATE_KEY,  $span_context->trace_state->to_string );
        }
        catch($e) {
            if ( $e isa OpenTelemetry::X ) { $logger->warn($e->get_message) }
            else {
                OpenTelemetry->handle_error(
                    exception => $e,
                    message   => 'Error while injecting trace context',
                );
            }
        }

        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Propagator::TextMap::GETTER
    ) {
        try {
            my $string = $getter->( $carrier, $TRACE_PARENT_KEY )
                or return $context;

            my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent
                ->from_string($string);

            my $trace_state = OpenTelemetry::Propagator::TraceContext::TraceState
                ->from_string( $getter->( $carrier, $TRACE_STATE_KEY ) // '' );

            my $span_context = OpenTelemetry::Trace::SpanContext->new(
                trace_id    => $trace_parent->trace_id,
                span_id     => $trace_parent->span_id,
                trace_flags => $trace_parent->trace_flags,
                trace_state => $trace_state,
                remote      => 1,
            );

            my $span = OpenTelemetry::Trace->non_recording_span( $span_context );

            return OpenTelemetry::Trace->context_with_span( $span, $context );
        }
        catch ($e) {
            if ( $e isa OpenTelemetry::X ) { $logger->warn($e->get_message) }
            else {
                OpenTelemetry->handle_error(
                    exception => $e,
                    message   => 'Error while extracting trace context',
                );
            }

            return $context;
        }
    }

    method keys () { ( $TRACE_PARENT_KEY, $TRACE_STATE_KEY ) }
}
