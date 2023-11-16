#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext::TraceFlags';
use Test2::Tools::OpenTelemetry;

no_messages {
    is CLASS->new(1), object {
        call flags   => 1;
        call sampled => T;
    }, 'Can create from number';

    is CLASS->new(0), object {
        call flags   => 0;
        call sampled => F;
    }, 'New with explicit 0';

    is CLASS->new, object {
        call flags   => 0;
        call sampled => F;
    }, 'Defaults to zero';

    is CLASS->new(undef), object {
        call flags   => 0;
        call sampled => F;
    }, 'Ignores undef';
};

is messages {
    is CLASS->new('deadbeef'), object {
        call flags   => 0;
        call sampled => F;
    }, 'Non-numeric flags ignored';

    is CLASS->new(-1), object {
        call flags   => 0;
        call sampled => F;
    }, 'Ignores negative values';

    is CLASS->new(256), object {
        call flags   => 0;
        call sampled => F;
    }, 'Ignores values above 255';
} => [
    [ warning => OpenTelemetry => match qr/Non-numeric value/  ],
    [ warning => OpenTelemetry => match qr/Non-numeric value/  ],
    [ warning => OpenTelemetry => match qr/Out-of-range value/ ],
], 'Logged invalid values';

done_testing;
