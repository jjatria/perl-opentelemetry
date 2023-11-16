#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Tracer';
use Test2::Tools::OpenTelemetry;

use experimental 'signatures';

use OpenTelemetry::Constants -span;

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

    my $mock = mock $tracer => override => [
        create_span => sub ( $, %args ) {
            mock \%args => track => 1 => add => [
                status => sub {
                    mock obj => add => [
                        is_unset => sub {
                            !( defined $args{status} )
                            || $args{status} == SPAN_STATUS_UNSET;
                        },
                    ];
                },
                set_status => sub ( $span, $status, @ ){
                    $span->{status} = $status;
                }
            ];
        },
    ];

    my ( $ret, $mocked );
    no_messages {
        $ret = $tracer->in_span( some_span => sub ( $span, $context ) {
            ref_is + OpenTelemetry::Trace->span_from_context($context),
                $span,
                'Received a context with the span';

            ($mocked) = mocked $span;

            return 'TEST';
        });
    };

    is $mocked->call_tracking, [
        {
            sub_name => 'status',
            args     => [ D ],
            sub_ref  => E,
        },
        {
            sub_name => 'set_status',
            args     => [ D, SPAN_STATUS_OK ],
            sub_ref  => E,
        },
        {   sub_name => 'end',
            args     => [ D ],
            sub_ref  => E,
        },
    ], 'Set status and ended at end of block';

    is $ret, 'TEST', 'in_span returns what the block returns';

    like dies { $tracer->in_span('name') },
        qr/^Missing required code block /, 'Requires code block';

    like dies { $tracer->in_span( sub { } ) },
        qr/^Missing required span name/, 'Requires span name';

    no_messages {
        is [ $tracer->in_span( foo => sub { qw( a b c ) } ) ],
            [qw( a b c )], 'Can return list context';
    };

    no_messages {
        like dies {
            $tracer->in_span(
                dead_span => sub ( $span, $context ) {
                    ($mocked) = mocked $span;
                    die 'An error';
                },
            );
        } => qr/^An error/, 'If sub dies, exception is not caught';
    };

    is $mocked->call_tracking, [
        {
            sub_name => 'record_exception',
            args     => [ D, match qr/^An error/ ],
            sub_ref  => E
        },
        {
            sub_name => 'status',
            args     => [ D ],
            sub_ref  => E
        },
        {
            sub_name => 'set_status',
            args     => [ D, SPAN_STATUS_ERROR, match qr/^An error/ ],
            sub_ref  => E
        },
        {
            sub_name => 'end',
            args     => [ D ],
            sub_ref  => E
        },
    ], 'Span records caught error';

    no_messages {
        like dies {
            $tracer->in_span(
                dead_span => sub ( $span, $context ) {
                    ($mocked) = mocked $span;
                    $span->set_status( SPAN_STATUS_ERROR, 'My error' );
                    die 'An error';
                },
            );
        } => qr/^An error/, 'If sub dies, exception is not caught';
    };

    is $mocked->call_tracking, [
        {
            sub_name => 'set_status',
            args     => [ D, SPAN_STATUS_ERROR, match qr/^My error/ ],
            sub_ref  => E
        },
        {
            sub_name => 'record_exception',
            args     => [ D, match qr/^An error/ ],
            sub_ref  => E
        },
        {
            sub_name => 'status',
            args     => [ D ],
            sub_ref  => E
        },
        {
            sub_name => 'end',
            args     => [ D ],
            sub_ref  => E
        },
    ], 'Status not set automatically if already set manually';
};

done_testing;
