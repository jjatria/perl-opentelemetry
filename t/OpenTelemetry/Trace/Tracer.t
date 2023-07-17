#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Tracer';

use experimental 'signatures';

use Scalar::Util 'refaddr';

is my $tracer = CLASS->new, object {
    prop isa => 'OpenTelemetry::Trace::Tracer';
}, 'Can construct tracer';

is $tracer->create_span( name => 'span' ), object {
    prop isa => 'OpenTelemetry::Trace::Span';
    call context => object { call valid => F };
}, 'Creates an invalid span';

todo 'Experimental API' => sub {
    use Log::Any::Adapter;
    use OpenTelemetry::Trace;

    Log::Any::Adapter->set(
        { lexically => \my $scope },
        Capture => to => \my @messages,
    );

    my $mock = mock $tracer => override => [
        create_span => sub ( $, %args ) { mock \%args => track => 1 }
    ];

    my $mocked;
    my $ret = $tracer->in_span( some_span => sub ( $span, $context ) {
        is refaddr + OpenTelemetry::Trace->span_from_context($context),
            refaddr $span,
            'Received a context with the span';

        ($mocked) = mocked $span;
    });

    is $mocked->call_tracking, [
        { sub_name => 'end', args => [ D ], sub_ref => E },
    ], 'Called span->end at end of block';

    is refaddr $ret, refaddr $tracer, 'in_span is chainable';

    is refaddr $tracer->in_span, refaddr $tracer,
        'in_span is chainable even when no block is provided';

    is \@messages, [
        [ warning => OpenTelemetry => match qr/^Missing required code block / ],
    ], 'Faulty call to in_span is logged';
};

done_testing;