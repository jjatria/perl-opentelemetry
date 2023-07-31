#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span::Status';

use OpenTelemetry::Test::Logs;

is CLASS->new, object {
    call description => '';
    call code        => 0;
    call is_unset    => T;
    call is_ok       => F;
    call is_error    => F;
}, 'Raw constructor defaults to unset';

is CLASS->unset, object {
    call description => '';
    call code        => 0;
    call is_unset    => T;
    call is_ok       => F;
    call is_error    => F;
}, 'Unset constructor sets to unset';

is CLASS->ok, object {
    call description => '';
    call code        => 1;
    call is_unset    => F;
    call is_ok       => T;
    call is_error    => F;
}, 'Ok constructor sets to ok';

is CLASS->error, object {
    call description => '';
    call code        => 2;
    call is_unset    => F;
    call is_ok       => F;
    call is_error    => T;
}, 'Error constructor sets to error';

OpenTelemetry::Test::Logs->clear;

is CLASS->unset( description => 'foo' ), object {
    call description => '';
    call code        => 0;
}, 'Unset constructor sets to unset';

is + OpenTelemetry::Test::Logs->messages, [
    [ warning => OpenTelemetry => 'Ignoring description on a non-error span status' ],
], 'Warns when setting a description on an unset status';

OpenTelemetry::Test::Logs->clear;

is CLASS->ok( description => 'foo' ), object {
    call description => '';
    call code        => 1;
}, 'Unset constructor sets to unset';

is + OpenTelemetry::Test::Logs->messages, [
    [ warning => OpenTelemetry => 'Ignoring description on a non-error span status' ],
], 'Warns when setting a description on an ok status';

OpenTelemetry::Test::Logs->clear;

is CLASS->error( description => 'foo' ), object {
    call description => 'foo';
    call code        => 2;
    call to_hash     => {
        description => 'foo',
        code        => 2,
    };
}, 'Unset constructor sets to unset';

is + OpenTelemetry::Test::Logs->messages, [],
    'Does not warn when setting a description on an error status';

done_testing;
