#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry';

is CLASS->logger, object {
    call [ can => 'error' ] => D;
    call [ can => 'warn'  ] => D;
}, '->logger returns a logger';

subtest 'Error handling' => sub {
    is CLASS->error_handler, meta {
        prop reftype => 'CODE';
    }, 'Can retrieve error handler';

    my $ok;
    is CLASS->error_handler( sub { $ok = 'ok' } ), meta {
        prop reftype => 'CODE';
    }, 'Setting error handler returns error handler';

    is CLASS->handle_error, U, 'Handle error returns nothing';

    is $ok, 'ok', '->handle_error calls error handler';
};

subtest TracerProvider => sub {
    is my $provider = CLASS->tracer_provider, object {
        prop isa => 'OpenTelemetry::Trace::TracerProvider';
    }, '->tracer_provider returns a TracerProvider';

    # TODO: More strict validation?
    my $mock = mock obj => add => [ tracer => sub { 'ok' } ];
    is CLASS->tracer_provider($mock)->tracer, 'ok',
        'Can set and retrieve global tracer provider';
};

subtest Propagation => sub {
    is my $prop = CLASS->propagation, object {
        prop isa => 'OpenTelemetry::Propagator::None';
    };
};

done_testing;
