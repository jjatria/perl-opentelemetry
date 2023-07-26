#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span::Status';

is CLASS->new, object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
    call to_string   => 'UNSET';
}, 'Defaults to unset';

is CLASS->new( description => 'foo' ), object {
    call description => 'foo';
    call ok          => F;
    call error       => F;
    call unset       => T;
    call to_string   => 'UNSET';
}, 'Can set description on construction';

is CLASS->new( code => 'OK', description => 'x' ), object {
    call description => 'x';
    call ok          => T;
    call error       => F;
    call unset       => F;
    call to_string   => 'OK';
}, 'Can set status to OK';

is CLASS->new( code => 'ERROR' ), object {
    call description => '';
    call ok          => F;
    call error       => T;
    call unset       => F;
    call to_string   => 'ERROR';
}, 'Can set status to ERROR';

is CLASS->new( code => 'error' ), object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
    call to_string   => 'UNSET';
}, 'Invalid statuses are left as unset';

is CLASS->new( code => undef ), object {
    call description => '';
    call ok          => F;
    call error       => F;
    call unset       => T;
    call to_string   => 'UNSET';
}, 'Undef treated as invalid status';

done_testing;
