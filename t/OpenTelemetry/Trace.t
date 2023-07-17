#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace';

use Scalar::Util 'refaddr';
use OpenTelemetry::Context;

is CLASS->span_from_context, object {
    call context => object {
        prop isa   => 'OpenTelemetry::Trace::SpanContext';
        call valid => F;

        # This is the same as calling 'valid' above
        call span_id  => CLASS->INVALID_SPAN_ID;
        call trace_id => CLASS->INVALID_TRACE_ID;
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

is refaddr CLASS->span_from_context($context), refaddr $span,
    'Can round-trip into and out of a context';

is CLASS->context_with_span( $span, $context->set( $key => 123 ) ), object {
    prop isa => 'OpenTelemetry::Context';
    call [ get => $key ], 123;
}, 'Can create a context with a span based on an existing context';

subtest 'Trace ID' => sub {
    is my $id = CLASS->generate_trace_id, T, 'Can generate a new one';
    is length $id, 16, 'Has the right length';
    isnt $id, CLASS->INVALID_TRACE_ID, 'Is valid';
};

subtest 'Span ID' => sub {
    is my $id = CLASS->generate_span_id, T, 'Can generate a new one';
    is length $id, 8, 'Has the right length';
    isnt $id, CLASS->INVALID_SPAN_ID, 'Is valid';
};

done_testing;
