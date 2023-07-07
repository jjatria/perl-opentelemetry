#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Context';

use OpenTelemetry;

my @messages;
my $handler = OpenTelemetry->error_handler;
OpenTelemetry->error_handler( sub { push @messages, $handler->(@_) } );

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

subtest 'Implicit context management' => sub {
    my $key = CLASS->key('x');

    is CLASS->current->get($key), U, 'Key is undefined in top-level context';

    is my $token = CLASS->attach( CLASS->current->set( $key => 123 ) ), T, 'Attached a context';
    is CLASS->current->get($key), 123, 'Attached context masks top-level';

    {
        is my $token = CLASS->attach( CLASS->current->set( $key => 234 ) ), T, 'Attached another context';
        is CLASS->current->get($key), 234, 'Attached context masks previous context';

        is CLASS->detach('123 bogus token'), F, 'Validate last-attached context';

        is CLASS->detach( $token ), T, 'Can detach this context';
        is CLASS->current->get($key), 123, 'Detacing a context unmasks previous context';

        is CLASS->detach( $token ), F, 'Cannot detach this context twice';
    }

    is CLASS->detach( $token ), T, 'Can detach last context';
    is CLASS->current->get($key), U, 'Detaching unmasked top-level context';

    is \@messages, [
        match(qr/calls to detach should match corresponding calls to attach/),
        match(qr/calls to detach should match corresponding calls to attach/),
    ], 'Logged incorrect calls to detach';
};

done_testing;
