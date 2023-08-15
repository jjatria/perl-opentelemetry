#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace';

use OpenTelemetry::Context;
use OpenTelemetry::Constants qw( INVALID_SPAN_ID INVALID_TRACE_ID );
use Syntax::Keyword::Dynamically;

is CLASS->span_from_context, object {
    call context => object {
        prop isa   => 'OpenTelemetry::Trace::SpanContext';
        call valid => F;

        # This is the same as calling 'valid' above
        call span_id  => INVALID_SPAN_ID;
        call trace_id => INVALID_TRACE_ID;
    };
}, 'Returns an invalid span when none found in context';

is my $span = CLASS->non_recording_span, object {
    call recording => F;
}, 'Can get a non-recording span';

is CLASS->non_recording_span( $span->context ), object {
    call recording => F;
}, 'Can get a non-recording span with a context';

like dies { CLASS->context_with_span },
    qr/Too few arguments for subroutine/,
    'Span is needed to create a context';

my $key = OpenTelemetry::Context->key('foo');

is my $context = CLASS->context_with_span($span), object {
    prop isa => 'OpenTelemetry::Context';
    call [ get => $key ], U;
}, 'Can create a fresh context with span';

ref_is CLASS->span_from_context($context), $span,
    'Can round-trip into and out of a context';

is CLASS->context_with_span( $span, $context->set( $key => 123 ) ), object {
    prop isa => 'OpenTelemetry::Context';
    call [ get => $key ], 123;
}, 'Can create a context with a span based on an existing context';

subtest 'Trace ID' => sub {
    is my $id = CLASS->generate_trace_id, T, 'Can generate a new one';
    is length $id, 16, 'Has the right length';
    isnt $id, INVALID_TRACE_ID, 'Is valid';
};

subtest 'Span ID' => sub {
    is my $id = CLASS->generate_span_id, T, 'Can generate a new one';
    is length $id, 8, 'Has the right length';
    isnt $id, INVALID_SPAN_ID, 'Is valid';
};

subtest 'Untraced context' => sub {
    my $root = OpenTelemetry::Context->current;

    is +OpenTelemetry::Trace->is_untraced_context, F,
        'Root context is not untraced';

    is +OpenTelemetry::Trace->is_untraced_context($root), F,
        'Explicit root context is not untraced';

    is my $untraced = OpenTelemetry::Trace->untraced_context, object {
        prop isa => 'OpenTelemetry::Context';
    }, 'Untraced returns an OpenTelemetry::Context object';

    is +OpenTelemetry::Trace->untraced_context($untraced), T,
        'Untraced context is explicitly detected as such';

    {
        dynamically OpenTelemetry::Context->current = $untraced;

        is +OpenTelemetry::Trace->is_untraced_context, T,
            'Current context is untraced';
    }

    is +OpenTelemetry::Trace->is_untraced_context, F,
        'Current context is again not untraced';
};

done_testing;
