#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext::TraceParent';

use OpenTelemetry::Trace::SpanContext;

subtest Parsing => sub {
    my $tp = CLASS->from_string('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01');

    is $tp, object {
        call version     => 0;
        call trace_id    => pack 'H*', '4bf92f3577b34da6a3ce929d0e0e4736';
        call span_id     => pack 'H*', '00f067aa0ba902b7';
        call trace_flags => object {
            call flags   => 1;
            call sampled => T;
        };
    }, 'Can parse TraceParent string';

    is $tp->to_string, '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
        'Can generate TraceParent string';

    is CLASS->from_string('01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01-'), object {
        call version => 1;
    }, 'Supports newer versions if backwards compatible';

    is CLASS->from_span_context(
        OpenTelemetry::Trace::SpanContext->new(
            span_id  => pack( 'H*', 'f0f1f2f3f4f5f6f7' ),
            trace_id => pack( 'H*', '000102030405060708090a0b0c0d0e0f' ),
        )
    )->to_string, '00-000102030405060708090a0b0c0d0e0f-f0f1f2f3f4f5f6f7-00', 'Parse from SpanContext';

    like dies { CLASS->from_string('00-deadbeef') },
        qr/^Could not parse TraceParent from string: '00-deadbeef'/,
        'Dies when unable to parse';

    like dies { CLASS->from_string('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01-extrastuff') },
        qr/^Malformed TraceParent string had trailing data after trace-flags:/,
        'Dies when parsing invalid trace ID';

    like dies { CLASS->from_string('00-00000000000000000000000000000000-00f067aa0ba902b7-01') },
        qr/^Invalid trace ID \(00000000000000000000000000000000\) when parsing string:/,
        'Dies when parsing invalid trace ID';

    like dies { CLASS->from_string('00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01') },
        qr/^Invalid span ID \(0000000000000000\) when parsing string:/,
        'Dies when parsing invalid span ID';

    like dies { CLASS->from_string('01-DEADBEEFE') },
        qr/^Unsupported TraceParent version \(01\) when parsing string:/,
        'Dies when parsing unsupported versions that are not backwards compatible';
};

done_testing;
