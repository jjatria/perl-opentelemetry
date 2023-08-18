#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span::Status';
use Test2::Tools::OpenTelemetry;

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

is messages {
    is CLASS->unset( description => 'foo' ), object {
        call description => '';
        call code        => 0;
    }, 'Unset constructor sets to unset';
} => [
    [ warning => OpenTelemetry => 'Ignoring description on a non-error span status' ],
], 'Warns when setting a description on an unset status';

is messages {
    is CLASS->ok( description => 'foo' ), object {
        call description => '';
        call code        => 1;
    }, 'Unset constructor sets to unset';
} => [
    [ warning => OpenTelemetry => 'Ignoring description on a non-error span status' ],
], 'Warns when setting a description on an ok status';

no_messages {
    is CLASS->error( description => 'foo' ), object {
        call description => 'foo';
        call code        => 2;
    }, 'Unset constructor sets to unset';
};

done_testing;
