#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Context';

my ($ctx, $key, $new);

$ctx = CLASS->new;
$key = $ctx->key('foo');

is $ctx, object { prop isa => 'OpenTelemetry::Context' };
is $key, object { prop isa => 'OpenTelemetry::Context::Key' };

isnt $key->string, $ctx->key('foo')->string,
    'Generating two keys with the same name returns different keys';

is $ctx->get($key), U, 'Key starts undefined';

is $new = $ctx->set( $key => 123 ),
    object { prop isa => 'OpenTelemetry::Context' },
    'Setting a key returns new context';

is $new->get($key), 123, 'Can read set value';
is $ctx->get($key), U, 'Original context is unaffected';

done_testing;
