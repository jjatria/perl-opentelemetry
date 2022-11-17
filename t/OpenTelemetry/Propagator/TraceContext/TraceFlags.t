#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext::TraceFlags';

is CLASS->new(1), object {
    call flags   => 1;
    call sampled => T;
}, 'Can create from number';

is CLASS->new(0), object {
    call flags   => 0;
    call sampled => F;
}, 'New with explicit 0';

is CLASS->new('deadbeef'), object {
    call flags   => 0;
    call sampled => F;
}, 'Non-numeric flags ignored';

is CLASS->new, object {
    call flags   => 0;
    call sampled => F;
}, 'Defaults to zero';

done_testing;
