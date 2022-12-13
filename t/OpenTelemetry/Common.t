#!/usr/bin/env perl

use Test2::V0;

use OpenTelemetry::Common qw(
    config
    maybe_timeout
    timeout_timestamp
    validate_attribute_value
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

subtest 'Validate attribute value' => sub {
    # Valid
    is validate_attribute_value('string'), 'string', 'String';
    is validate_attribute_value( 123456 ),  123456 , 'Integer';
    is validate_attribute_value( 123.56 ),  123.56 , 'Float';
    is validate_attribute_value(      0 ),       0 , 'Zero';
    is validate_attribute_value(  undef ),   undef , 'Undef';

    # NOTE: We cannot validate types in Perl
    is validate_attribute_value([ 1, 'string', undef, 4 ]),
        [ 1, 'string', undef, 4 ], 'Array reference';

    # Invalid
    is validate_attribute_value({}), U, 'Hash reference';
    is validate_attribute_value([ 1, {}, 3 ]), U, 'Array reference with reference';

};

done_testing;
