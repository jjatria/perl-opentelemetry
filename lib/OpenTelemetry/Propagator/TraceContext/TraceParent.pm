use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Represents a TraceParent in a W3C TraceContext

package OpenTelemetry::Propagator::TraceContext::TraceParent;

our $VERSION = '0.025';

class OpenTelemetry::Propagator::TraceContext::TraceParent {
    use OpenTelemetry::X;
    use OpenTelemetry::Constants qw(
        HEX_INVALID_TRACE_ID
        HEX_INVALID_SPAN_ID
    );
    use OpenTelemetry::Propagator::TraceContext::TraceFlags;

    field $span_id     :param :reader;
    field $trace_flags :param :reader;
    field $trace_id    :param :reader;
    field $version     :param :reader = 0;

    method to_string () {
        join '-',
            '00',
            unpack( 'H*', $trace_id ),
            unpack( 'H*', $span_id  ),
            $trace_flags->to_string;
    }

    sub from_span_context ( $class, $context ) {
        $class->new(
            span_id     => $context->span_id,
            trace_flags => $context->trace_flags,
            trace_id    => $context->trace_id,
        );
    }

    sub from_string ( $class, $string ) {
        my $version = substr $string, 0, 2;

        die OpenTelemetry::X->create(
            'Unsupported',
            "Unsupported TraceParent version ($version) when parsing string: $string"
        ) if !$version
            || $version !~ /^\d+$/a
            || ( $version > 0 && length $string < 55 );

        my ( $trace_id, $span_id, $trace_flags ) = $string =~ /
            ^  [A-Za-z0-9]{2}   # version
            - ([A-Za-z0-9]{32}) # trace ID
            - ([A-Za-z0-9]{16}) # span ID
            - ([A-Za-z0-9]{2})  # trace flags
            ( $ | - )
        /x or die OpenTelemetry::X->create(
            'Parsing',
            "Could not parse TraceParent from string: '$string'"
        );

        die OpenTelemetry::X->create(
            'Parsing',
            "Malformed TraceParent string had trailing data after trace-flags: '$string'"
        ) if $version == 0 && length $string > 55;

        die OpenTelemetry::X->create(
            'Parsing',
            "Invalid trace ID ($trace_id) when parsing string: '$string'"
        ) if $trace_id eq HEX_INVALID_TRACE_ID;

        die OpenTelemetry::X->create(
            'Parsing',
            "Invalid span ID ($span_id) when parsing string: '$string'"
        ) if $span_id eq HEX_INVALID_SPAN_ID;

        $class->new(
            version     => 0+$version,
            trace_id    => pack( 'H*', $trace_id ),
            span_id     => pack( 'H*', $span_id ),
            trace_flags => OpenTelemetry::Propagator::TraceContext::TraceFlags
                ->new( hex $trace_flags ),
        );
    }
}
