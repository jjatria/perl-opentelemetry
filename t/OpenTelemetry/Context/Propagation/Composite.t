#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Context::Propagation::Composite';

use OpenTelemetry::Baggage;
use OpenTelemetry::Trace;
use OpenTelemetry::Propagator::TraceContext::TraceParent;
use OpenTelemetry::Propagator::TraceContext::TraceFlags;
use OpenTelemetry::Trace::SpanContext;
use OpenTelemetry::Propagator::Baggage;
use OpenTelemetry::Propagator::TraceContext;

my $context = do {
    my $parent = OpenTelemetry::Propagator::TraceContext::TraceParent->new(
        trace_id => pack( 'H*', '000102030405060708090a0b0c0d0e0f' ),
        span_id  => pack( 'H*', '0001020304050607' ),
        flags => OpenTelemetry::Propagator::TraceContext::TraceFlags->new,
    );

    my $state  = OpenTelemetry::Propagator::TraceContext::TraceState
        ->from_string('foo=123,bar=234');

    my $span_context = OpenTelemetry::Trace::SpanContext->new(
        trace_id    => $parent->trace_id,
        span_id     => $parent->span_id,
        trace_flags => $parent->flags,
        trace_state => $state,
        remote      => 1,
    );

    my $span = OpenTelemetry::Trace->non_recording_span( $span_context );

    OpenTelemetry::Trace->context_with_span(
        $span => OpenTelemetry::Baggage->set( abc => 'ABC', 'META' ),
    );
};

my $carrier = {};
my $prop = CLASS->new(
    injectors  => [
        OpenTelemetry::Propagator::Baggage->new,
        OpenTelemetry::Propagator::TraceContext->new,
    ],
    extractors => [
        OpenTelemetry::Propagator::Baggage->new,
        OpenTelemetry::Propagator::TraceContext->new,
    ],
);

ref_is $prop->inject( $carrier, $context ), $prop, 'Inject returns self';

is $carrier, {
    baggage => 'abc=ABC;META',
    traceparent => '00-000102030405060708090a0b0c0d0e0f-0001020304050607-00',
    tracestate  => 'foo=123,bar=234',
}, 'Baggage injected into carrier';

is $prop->extract($carrier), object {
    prop isa => 'OpenTelemetry::Context';
    # Extracts Baggage
    prop this => validator sub {
        my $entry = OpenTelemetry::Baggage->get( abc => $_ );
           $entry
        && $entry->value eq 'ABC'
        && $entry->meta  eq 'META';
    };
    # Extracts TraceContext
    prop this => validator sub {
        my $sctx = OpenTelemetry::Trace->span_from_context($_)->context;
           $sctx
        && $sctx->hex_trace_id eq '000102030405060708090a0b0c0d0e0f'
        && $sctx->hex_span_id  eq '0001020304050607'
        && $sctx->trace_state->to_string eq 'foo=123,bar=234'
        && $sctx->remote;
    };
}, 'Extract';

is CLASS->new, object {
    prop isa => $CLASS;
}, 'Constructor can be called with no injectors / extractors for no-op instance';

like dies { CLASS->new( injectors => [ mock ] ) },
    qr/^Injector for Composite propagator does not support an 'inject' method: Test2::Tools::.*/,
    'Validate injectors';

like dies { CLASS->new( extractors => [ mock ] ) },
    qr/^Extractor for Composite propagator does not support an 'extract' method: Test2::Tools::.*/,
    'Validate injectors';

is [ sort $prop->keys ] , [qw( baggage traceparent tracestate )], 'Get compound keys';

done_testing;
