#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::TracerProvider::Proxy';

use experimental 'signatures';

use Scalar::Util 'refaddr';
use OpenTelemetry::Test::Logs;

is my $provider = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct a provider';

is my $tracer = $provider->tracer,
    object { prop isa => 'OpenTelemetry::Trace::Tracer' },
    'Can provide a tracer';

is refaddr $provider->tracer, refaddr $tracer,
    'Provided tracer is cached internally';

subtest Delegate => sub {
    my $provider = CLASS->new;

    is my $empty_tracer = $provider->tracer, object {
        prop isa => 'OpenTelemetry::Trace::Tracer::Proxy';
        call delegate => U;
    }, 'Proxy TracerProvider returns a proxy Tracer';

    is my $other_tracer = $provider->tracer( name => 'other' ), object {
        prop isa  => 'OpenTelemetry::Trace::Tracer::Proxy';
        prop this => validator sub { refaddr $_ ne $empty_tracer };
        call delegate => U;
    }, 'Proxy TracerProvider returns namespaced tracers';

    is $empty_tracer->create_span, object {
        prop isa => 'OpenTelemetry::Trace::Span';
        call context => object { call valid => F };
    }, 'Default tracer creates invalid spans';

    like dies { $provider->delegate }, qr/^Too few arguments /,
        'Call to delegate requires a delegate';

    my $mock = mock {} => track => 1 => add => [
        tracer => sub ( $, %args ) {
            mock \%args => add => [
                create_span => sub { 'a span' }
            ]
        },
    ];

    is refaddr $provider->delegate($mock), refaddr $provider,
        'call to delegate is chainable';

    like $empty_tracer->delegate, { name => '' },
        'Delegate propagates to existing tracers without name';

    like $other_tracer->delegate, { name => 'other' },
        'Delegate propagates to existing tracers with name';

    is $empty_tracer->create_span, 'a span',
        'Default tracer creates spans through delegate';

    isnt ref $provider->tracer( name => 'another' ),
        'OpenTelemetry::Trace::Tracer::Proxy',
        'New tracers are not proxies';

    OpenTelemetry::Test::Logs->clear;

    is refaddr $provider->delegate( mock {} => add => [ tracer => sub { die } ] ),
        refaddr $provider,
        'call to delegate is chainable even if ignored';

    is + OpenTelemetry::Test::Logs->messages, [
        [ warning => OpenTelemetry => match qr/^Attempt to reset delegate .* ignored/ ],
    ], 'Repeated call to delegate logged';
};

done_testing;
