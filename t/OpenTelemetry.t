#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry';
use OpenTelemetry -all;

use Object::Pad;
use Syntax::Keyword::Dynamically;

class Fake::TracerProvider :isa(OpenTelemetry::Trace::TracerProvider) {
    field $x :param;
    method tracer { $x }
}

class Fake::Propagator :does(OpenTelemetry::Propagator) {
    field $x :param;
    method extract { }
    method inject { }
    method keys { $x }
}

subtest Logger => sub {
    is CLASS->logger, object {
        call [ can => 'error' ] => D;
        call [ can => 'warn'  ] => D;
    }, '->logger returns a logger';

    is otel_logger, object {
        call [ can => 'error' ] => D;
        call [ can => 'warn'  ] => D;
    }, 'otel_logger returns a logger';
};

subtest 'Error handling' => sub {
    is my $code = CLASS->error_handler, meta {
        prop reftype => 'CODE';
    }, '->error_handler can retrieve error handler';

    is otel_error_handler, meta {
        prop reftype => 'CODE';
    }, 'otel_error_handler can retrieve error handler';

    like dies { CLASS->error_handler = 'not a code ref' },
        qr/Global error handler must be a code reference/,
        '->error_handler validates new value';

    like dies { otel_error_handler = 'not a code ref' },
        qr/Global error handler must be a code reference/,
        'otel_error_handler validates new value';

    {
        my $ok;
        dynamically CLASS->error_handler = sub { $ok = 'ok' };
        is CLASS->handle_error, U, '->handle_error returns nothing';
        is $ok, 'ok', '->handle_error calls error handler';
    }

    {
        my $ok;
        dynamically otel_error_handler = sub { $ok = 'ok' };
        is otel_handle_error, U, 'otel_handle_error returns nothing';
        is $ok, 'ok', 'otel_handle_error calls error handler';
    }

    ref_is otel_error_handler, $code, 'Error handler was dynamically scoped';
};

subtest 'Tracer provider' => sub {
    is my $provider = CLASS->tracer_provider, object {
        prop isa => 'OpenTelemetry::Trace::TracerProvider';
    }, '->tracer_provider returns default TracerProvider';

    {
        dynamically otel_tracer_provider = Fake::TracerProvider->new( x => 2 );

        is otel_tracer_provider->tracer, 2,
            'otel_tracer_provider can set and retrieve global tracer provider';

        {
            dynamically CLASS->tracer_provider = Fake::TracerProvider->new( x => 1 );

            is CLASS->tracer_provider->tracer, 1,
                '->tracer_provider can set and retrieve global tracer provider';
        }

        is CLASS->tracer_provider->tracer, 2,
            '->tracer_provider was dynamically scoped';
    }

    ref_is CLASS->tracer_provider, $provider,
        '->tracer_provider again returns default TracerProvider';

    ref_is otel_tracer_provider, $provider,
        'otel_tracer_provider returns same default TracerProvider';

    like dies { CLASS->tracer_provider = mock },
        qr/Global tracer provider must be a subclass of/,
        '->tracer_provider validates new value';

    like dies { otel_tracer_provider = mock },
        qr/Global tracer provider must be a subclass of/,
        'otel_tracer_provider validates new value';
};

subtest Propagator => sub {
    is my $prop = CLASS->propagator, object {
        prop isa => 'OpenTelemetry::Propagator::None';
    }, '->propagator returns default propagator';

    {
        dynamically otel_propagator = Fake::Propagator->new( x => 1 );

        is otel_propagator->keys, 1,
            'otel_propagator can set and retrieve global propagator';

        {
            dynamically CLASS->propagator = Fake::Propagator->new( x => 2 );

            is CLASS->propagator->keys, 2,
                '->propagator can set and retrieve global propagator';
        }

        is CLASS->propagator->keys, 1,
            '->propagator was dynamically scoped';
    }

    ref_is otel_propagator, $prop,
        'otel_propagator returns default propagator';
};

subtest Helpers => sub {
    subtest 'Current context' => sub {
        is my $context = otel_current_context, object {
            prop isa => 'OpenTelemetry::Context';
        }, 'otel_current_context can read context';

        my $key = $context->key('foo');

        {
            dynamically otel_current_context = $context->set( $key => 123 );
            is otel_current_context->get($key), 123, 'Can read set context';
        }

        is otel_current_context->get($key), U, 'Can set context dynamically';
    };

    subtest 'Contextual span' => sub {
        my $span = mock;
        is my $context = otel_context_with_span( $span ), object {
            prop isa => 'OpenTelemetry::Context';
        }, 'Can write span to context';

        ref_is otel_span_from_context( $context ), $span,
            'Can read span from context';

        ref_is_not otel_span_from_context, $span,
            'Span in current context is not new one';

        dynamically otel_current_context = $context;

        ref_is otel_span_from_context, $span,
            'Reads span from current context';
    };
};

done_testing;
