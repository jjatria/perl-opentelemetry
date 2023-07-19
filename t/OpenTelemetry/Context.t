#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Context';

use OpenTelemetry;
use OpenTelemetry::Test::Logs;

my ($ctx, $key, $new);

$ctx = CLASS->new;
$key = $ctx->key('foo');

is $ctx, object { prop isa => 'OpenTelemetry::Context' }, 'Constructed a context';
is $key, object { prop isa => 'OpenTelemetry::Context::Key' }, 'Constructed a key';

isnt $key->string, $ctx->key('foo')->string,
    'Generating two keys with the same name returns different keys';

is $ctx->get($key), U, 'Key starts undefined';

is $new = $ctx->set( $key => 123 ),
    object { prop isa => 'OpenTelemetry::Context' },
    'Setting a key returns new context';

is $new->get($key), 123, 'Can read set value';
is $ctx->get($key), U, 'Original context is unaffected';

is $new->delete($key),
    object { call [ get => $key ] => U },
    'Can delete a value from the context';

is $new->get($key), 123, 'Original context is unaffected';

like dies { $ctx->get('foo') },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on get';

like dies { $ctx->set( foo => 123 ) },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on set';

like dies { $ctx->delete('foo') },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on delete';

subtest 'Implicit context management' => sub {
    my $key = CLASS->key('x');

    is CLASS->current->get($key), U, 'Key is undefined in top-level context';

    is my $token = CLASS->attach( CLASS->current->set( $key => 123 ) ), T, 'Attached a context';
    is CLASS->current->get($key), 123, 'Attached context masks top-level';

    {
        is my $token = CLASS->current->set( $key => 234 )->attach, T, 'Attached another context';
        is CLASS->current->get($key), 234, 'Attached context masks previous context';

        is my $null = CLASS->attach( \1 ), T, 'Attaching a non-context does not modify stack';
        is CLASS->detach($null), F , 'Detaching a null token has no effect';
        is CLASS->detach($null), F , 'Detaching a null token really has no effect';

        is CLASS->detach('123 bogus token'), F, 'Validate last-attached context';

        is CLASS->detach( $token ), T, 'Can detach this context';
        is CLASS->current->get($key), 123, 'Detacing a context unmasks previous context';

        is CLASS->detach( $token ), F, 'Cannot detach this context twice';
    }

    is CLASS->detach( $token ), T, 'Can detach last context';
    is CLASS->current->get($key), U, 'Detaching unmasked top-level context';

    is + OpenTelemetry::Test::Logs->messages, [
        [ error => OpenTelemetry => match qr/cannot attach without a context object/ ],
        [ error => OpenTelemetry => match qr/calls to detach should match corresponding calls to attach/ ],
        [ error => OpenTelemetry => match qr/calls to detach should match corresponding calls to attach/ ],
    ], 'Logged incorrect calls to detach and attach';
};

done_testing;
