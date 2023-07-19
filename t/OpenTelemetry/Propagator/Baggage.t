#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::Baggage';

use Scalar::Util 'refaddr';
use OpenTelemetry::Context;
use OpenTelemetry::Baggage;
use OpenTelemetry::Propagator::Baggage;

my $carrier = {};

my $propagator = CLASS->new;

is my $KEY = $propagator->keys, 'baggage', 'Can read propagator keys';

# Extracting baggage from a carrier that has had
# no baggage injected into it returns the current context
# or whatever context has been provided
subtest 'Extract without baggage' => sub {
    is my $a = $propagator->extract($carrier),
        object { prop isa => 'OpenTelemetry::Context' },
        'Returns current context if none provided';

    my $key = $a->key('x');

    is my $b = $propagator->extract( $carrier, $a->set( $key, 123 ) ),
        object { prop isa => 'OpenTelemetry::Context' },
        'Returns provided context if not in carrier';

    is $b->get($key), 123, 'Can read from defaulted context';
};

# Injecting baggage into a carrier if no baggage exists in the
# provided context (or in the current context, if no context was
# provided) leaves the carrier untouched
subtest 'Inject without baggage' => sub {
    is refaddr $propagator->inject($carrier), refaddr $propagator,
        'Inject returns self with no context';
    is $carrier, {}, 'Nothing injected';

    is refaddr $propagator->inject( $carrier, OpenTelemetry::Context->current ),
        refaddr $propagator,
        'Inject returns self with context with no baggage';
    is $carrier, {}, 'Nothing injected';
};

# If there is baggage in the context, this is injected into the
# carrier. If no context is provided, then the baggage is read from
# the current context
subtest 'Inject with baggage' => sub {
    my $context = OpenTelemetry::Baggage->set( foo => 123, 'META' );

    is refaddr $propagator->inject( $carrier, $context ), refaddr $propagator,
        'Inject returns self';

    is $carrier, { $KEY => 'foo=123;META' }, 'Baggage injected into carrier';
};

# If the carrier has had baggage injected into it, then extract will
# return a context that contains it. We can read the baggage from the
# context, which returns an object representing the read entry
subtest 'Extract with baggage' => sub {
    is my $ctx = $propagator->extract($carrier),
        object { prop isa => 'OpenTelemetry::Context' },
        'Extract returns context';

    is + OpenTelemetry::Baggage->get( 'foo', $ctx ), object {
        prop isa   => 'OpenTelemetry::Baggage::Entry';
        call value => '123';
        call meta  => 'META';
    }, 'Baggage can read injected key from extracted context';
};

done_testing;
