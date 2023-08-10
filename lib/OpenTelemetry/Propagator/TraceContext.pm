use Object::Pad;
# ABSTRACT: Propagate context using the W3C TraceContext format

package OpenTelemetry::Propagator::TraceContext;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category =>'OpenTelemetry' );

class OpenTelemetry::Propagator::TraceContext :does(OpenTelemetry::Propagator) {
    use experimental 'isa';

    use Feature::Compat::Try;
    use URL::Encode qw( url_decode_utf8 url_encode_utf8 );

    use OpenTelemetry::Propagator::TextMap;
    use OpenTelemetry::Propagator::TraceContext::TraceParent;
    use OpenTelemetry::Propagator::TraceContext::TraceState;
    use OpenTelemetry::Trace::SpanContext;
    use OpenTelemetry::Trace;

    my $TRACE_PARENT_KEY = 'traceparent';
    my $TRACE_STATE_KEY  = 'tracestate';

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Propagator::TextMap::SETTER
    ) {
        my $span_context = OpenTelemetry::Trace->span_from_context($context)->context;
        return $self unless $span_context->valid;

        my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent
            ->from_span_context($span_context);

        $setter->( $carrier, $TRACE_PARENT_KEY, $trace_parent->to_string );
        $setter->( $carrier, $TRACE_STATE_KEY,  $span_context->trace_state->to_string );

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

            my $trace_parent = OpenTelemetry::Propagator::TraceContext::TraceParent->from_string($string);
            my $trace_state  = OpenTelemetry::Propagator::TraceContext::TraceState->from_string(
                $getter->( $carrier, $TRACE_STATE_KEY ) // '',
            );

            my $span_context = OpenTelemetry::Trace::SpanContext->new(
                trace_id    => $trace_parent->trace_id,
                span_id     => $trace_parent->span_id,
                trace_flags => $trace_parent->flags,
                trace_state => $trace_state,
                remote      => 1,
            );

            my $span = OpenTelemetry::Trace->non_recording_span( $span_context );

            return OpenTelemetry::Trace->context_with_span( $span, $context );
        }
        catch ($e) {
            die $e unless $e isa OpenTelemetry::X;
            $logger->warn($e);
            return $context;
        }
    }

    method keys () { ( $TRACE_PARENT_KEY, $TRACE_STATE_KEY ) }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Propagator::TraceContext - Propagate context using the W3C TraceContext format

=head1 SYNOPSIS

    use OpenTelemetry::Trace;
    use OpenTelemetry::Propagator::TraceContext;

    my $propagator = OpenTelemetry::Propagator::TraceContext;

    # Inject TraceContext data from the context to a carrier
    my $carrier = {};
    $propagator->inject( $carrier, $context );

    # Extract TraceContext data from a carrier to the context
    my $new_context = $propagator->extract( $carrier, $context );

    # The TraceContext data will be in the span in the context
    my $span = OpenTelemetry::Trace->span_from_context($new_context);


=head1 DESCRIPTION

This package defines a propagator class that can interact with the context
(which can be either an implicit or explicit instance of
L<OpenTelemetry::Context>) and inject or extract data using the
L<W3C TraceContext format|https://w3c.github.io/trace-context>.

It implements the propagator interface defined in
L<OpenTelemetry::Propagator>.

=head1 METHODS

=head2 inject

    $propagator = $propagator->inject(
        $carrier,
        $context // OpenTelemetry::Context->current,
        $setter  // OpenTelemetry::Propagator::TextMap::SETTER,
    )

=head2 extract

    $new_context = $propagator->extract(
        $carrier,
        $context // OpenTelemetry::Context->current,
        $getter  // OpenTelemetry::Propagator::TextMap::GETTER,
    )

=head2 keys

    @keys = $propagator->keys

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Context>

=item L<OpenTelemetry::Propagator>

=item L<W3C TraceContext format|https://w3c.github.io/trace-context>

=back

=head1 COPYRIGHT AND LICENSE

...
