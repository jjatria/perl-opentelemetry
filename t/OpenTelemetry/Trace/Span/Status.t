#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span::Status';

is CLASS->new, object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
}, 'Defaults to unset';

is CLASS->new( description => 'foo' ), object {
    call description => 'foo';
    call ok          => F;
    call error       => F;
    call unset       => T;
}, 'Can set description on construction';

is CLASS->new( code => 'OK', description => 'x' ), object {
    call description => 'x';
    call ok          => T;
    call error       => F;
    call unset       => F;
}, 'Can set status to OK';

is CLASS->new( code => 'ERROR' ), object {
    call description => '';
    call ok          => F;
    call error       => T;
    call unset       => F;
}, 'Can set status to ERROR';

is CLASS->new( code => 'error' ), object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
}, 'Invalid statuses are left as unset';

is CLASS->new( code => undef ), object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
}, 'Undef treated as invalid status';

done_testing;
