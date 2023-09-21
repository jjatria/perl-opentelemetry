#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext';
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Trace;
use OpenTelemetry::Propagator::TraceContext::TraceParent;
use OpenTelemetry::Propagator::TraceContext::TraceState;

my $carrier = {};

is my $propagator = CLASS->new, object {
    call_list keys => [qw( traceparent tracestate )];
}, 'Can create a propagator with correct keys';

subtest 'Extract without baggage' => sub {
    is my $a = $propagator->extract($carrier),
        object { prop isa => 'OpenTelemetry::Context' },
        'Returns current context if none provided';

    my $key = $a->key('x');

    is my $b = $propagator->extract( $carrier, $a->set( $key, 123 ) ),
        object { prop isa => 'OpenTelemetry::Context' },
        'Returns provided context if not in carrier';

    is $b->get($key), 123, 'Can read from defaulted context';
};

subtest 'Inject without TraceContext' => sub {
    ref_is $propagator->inject($carrier), $propagator,
        'Inject returns self with no context';
    is $carrier, {}, 'Nothing injected';

    ref_is $propagator->inject( $carrier, OpenTelemetry::Context->current ),
        $propagator,
        'Inject returns self with context with no tracecontext';
    is $carrier, {}, 'Nothing injected';
};

subtest 'Inject with TraceContext' => sub {
    my $parent = OpenTelemetry::Propagator::TraceContext::TraceParent->new(
        trace_id    => pack( 'H*', '000102030405060708090a0b0c0d0e0f' ),
        span_id     => pack( 'H*', '0001020304050607' ),
        trace_flags => OpenTelemetry::Propagator::TraceContext::TraceFlags->new,
    );

    my $state  = OpenTelemetry::Propagator::TraceContext::TraceState
        ->from_string('foo=123,bar=234');

    my $span_context = OpenTelemetry::Trace::SpanContext->new(
        trace_id    => $parent->trace_id,
        span_id     => $parent->span_id,
        trace_flags => $parent->trace_flags,
        trace_state => $state,
        remote      => 1,
    );

    my $span = OpenTelemetry::Trace->non_recording_span( $span_context );

    my $context = OpenTelemetry::Trace->context_with_span($span);

    ref_is $propagator->inject( $carrier, $context ), $propagator,
        'Inject returns self';

    is $carrier, {
        traceparent => '00-000102030405060708090a0b0c0d0e0f-0001020304050607-00',
        tracestate  => 'foo=123,bar=234',
    }, 'Baggage injected into carrier';
};

subtest 'Extract with TraceContext' => sub {
    no_messages {
        is my $context = $propagator->extract($carrier),
            object { prop isa => 'OpenTelemetry::Context' },
            'Extract returns context';

        is + OpenTelemetry::Trace->span_from_context($context)->context, object {
            prop isa => 'OpenTelemetry::Trace::SpanContext';
            call hex_trace_id => '000102030405060708090a0b0c0d0e0f';
            call hex_span_id  => '0001020304050607';
            call trace_state  => object { call to_string => 'foo=123,bar=234' };
            call remote       => T;
        }, 'Can extract injected TraceContext';
    };

    $carrier->{traceparent} = 'some garbage';

    is messages {
        is $propagator->extract($carrier),
            object { prop isa => 'OpenTelemetry::Context' },
            'Extract returns context when things go wrong';
    } => [
        [ warning => OpenTelemetry => match qr/^Unsupported .* version \(so\)/ ],
    ], 'Possible errors are logged';
};

done_testing;
