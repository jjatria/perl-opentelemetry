#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Context';

use OpenTelemetry;
use Syntax::Keyword::Dynamically;

my ($ctx, $key, $otr, $new);

$ctx = CLASS->new;
$key = $ctx->key('foo');
$otr = $ctx->key('bar');

like warning { CLASS->new( foo => 123 ) },
    qr/constructor no longer takes arguments/,
    'Constructor no longer takes arguments and warns about it';

is $ctx, object { prop isa => 'OpenTelemetry::Context' }, 'Constructed a context';
is $key, object { prop isa => 'OpenTelemetry::Context::Key' }, 'Constructed a key';

isnt $key->string, $ctx->key('foo')->string,
    'Generating two keys with the same name returns different keys';

is $ctx->get($key), U, 'Key starts undefined';

is $new = $ctx->set( $key => 12 ),
    object { prop isa => 'OpenTelemetry::Context' },
    'Setting a key returns new context';

is $new->get($key), 12, 'Can read set value';
is $ctx->get($key), U, 'Original context is unaffected';

is $new = $ctx->set( $key => 234, $key => 123, $otr => 'abc' ),
    object { prop isa => 'OpenTelemetry::Context' },
    'Setting multiple keys returns new context';

is $new->get($key), 123, 'Later assignments override earlier ones';
is $new->get($otr), 'abc', 'All set values are set';

is $new->delete( $otr, $key ),
    object {
        call [ get => $key ] => U;
        call [ get => $otr ] => U;
    },
    'Can delete values from the context';

is $new->get($key), 123, 'Original context is unaffected';

like dies { $ctx->get('foo') },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on get';

like dies { $ctx->set( $key => 123, foo => 123, $otr => 'abc' ) },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on set';

like dies { $ctx->delete( $key, 'foo', $otr ) },
    qr/^Keys in a context object must be instances of OpenTelemetry::Context::Key/,
    'Validate key on delete';

subtest 'Context management' => sub {
    my $key = CLASS->key('x');

    is CLASS->current->get($key), U, 'Key is undefined in top-level context';

    {
        dynamically CLASS->current = CLASS->current->set( $key => 123 );
        is CLASS->current->get($key), 123, 'New context masks top-level';

        {
            dynamically CLASS->current = CLASS->current->set( $key => 234 );
            is CLASS->current->get($key), 234, 'New context masks old context';
        }

        is CLASS->current->get($key), 123, 'Restored previous context';

        like dies { CLASS->current = 'garbage' },
            qr/^Current context must be an instance of OpenTelemetry::Context/,
            'Current context is validated on write';

        is CLASS->current->get($key), 123, 'Failed modification does nothing';
    }

    is CLASS->current->get($key), U, 'Back to top-level context';
};

done_testing;
