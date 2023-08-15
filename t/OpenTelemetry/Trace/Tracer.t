#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Tracer';

use experimental 'signatures';

use OpenTelemetry::Test::Logs;

is my $tracer = CLASS->new, object {
    prop isa => 'OpenTelemetry::Trace::Tracer';
}, 'Can construct tracer';

is $tracer->create_span( name => 'span' ), object {
    prop isa => 'OpenTelemetry::Trace::Span';
    call context => object { call valid => F };
}, 'Creates an invalid span';

subtest 'Convenience in_span method' => sub {
    my $todo = todo 'Experimental API';

    use OpenTelemetry::Trace;

    OpenTelemetry::Test::Logs->clear;

    my $mock = mock $tracer => override => [
        create_span => sub ( $, %args ) { mock \%args => track => 1 }
    ];

    my $mocked;
    my $ret = $tracer->in_span( some_span => sub ( $span, $context ) {
        ref_is + OpenTelemetry::Trace->span_from_context($context),
            $span,
            'Received a context with the span';

        ($mocked) = mocked $span;

        return 'TEST';
    });

    is $mocked->call_tracking, [
        { sub_name => 'end', args => [ D ], sub_ref => E },
    ], 'Called span->end at end of block';

    is $ret, 'TEST', 'in_span returns what the block returns';

    is + OpenTelemetry::Test::Logs->messages, [
        [ warning => OpenTelemetry => match qr/^Missing required code block / ],
    ], 'Faulty call to in_span is logged';

    is [ $tracer->in_span( foo => sub { qw( a b c ) } ) ],
        [qw( a b c )], 'Can return list context';
};

done_testing;
