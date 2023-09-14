#!/usr/bin/env perl

use Test2::V0;

use OpenTelemetry::Constants qw(
    INVALID_TRACE_ID
    INVALID_SPAN_ID
);

use OpenTelemetry::Common qw(
    config
    maybe_timeout
    timeout_timestamp
    generate_span_id
    generate_trace_id
);

subtest Timeout => sub {
    is my $start = timeout_timestamp, T, 'Can get a monotonic timestamp';

    is maybe_timeout(), U, 'No timeout';

    is maybe_timeout( undef, undef ), U, 'No timeout with explicit undefs';

    is maybe_timeout(0), 0, 'No time remaining';

    is maybe_timeout(10, $start - 3), float( 7, tolerance => 0.1 ),
        'Some time remaining';
};

subtest Config => sub {
    local %ENV = (
        OTEL_PERL_FOO => 'OTEL_PERL_FOO',
        OTEL_FOO      => 'OTEL_FOO',
        OTEL_BAR      => 'OTEL_BAR',
        OTEL_UNDEF    => undef,
        OTEL_EMPTY    => '',
        OTEL_ZERO     => 0,
        OTEL_TRUE     => 'TruE',
        OTEL_FALSE    => 'fALSe',
    );

    is config('BAR'), 'OTEL_BAR', 'Uses OTEL prefix';
    is config('FOO'), 'OTEL_PERL_FOO', 'Prefers PERL versions';
    is config('MISSING'), U, 'Returns undef for missing';
    is config('MISSING', 'BAR', 'FOO'), 'OTEL_BAR', 'Can fallback when undefined';
    is config('EMPTY', 'FOO', 'BAR'),  'OTEL_PERL_FOO', 'Falls back when empty';
    is config('MISSING', 'UNDEF', 'EMPTY', 'ZERO'), 0, 'Ignores unset and empty, but not zero';

    is config('TRUE'), T, 'Reads "true" case insensitively as a true value';
    is config('FALSE'), F, 'Reads "false" case insensitively as a false value';
};

subtest 'Trace ID' => sub {
    is my $id = generate_trace_id, T, 'Can generate a new one';
    is length $id, 16, 'Has the right length';
    isnt $id, INVALID_TRACE_ID, 'Is valid';
};

subtest 'Span ID' => sub {
    is my $id = generate_span_id, T, 'Can generate a new one';
    is length $id, 8, 'Has the right length';
    isnt $id, INVALID_SPAN_ID, 'Is valid';
};

done_testing;
