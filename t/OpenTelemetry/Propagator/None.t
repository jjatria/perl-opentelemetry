#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::None';
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Context;

my $root = OpenTelemetry::Context->current;

my $carrier = {};

is my $prop = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct propagator';

no_messages {
    ref_is $prop->inject( $carrier, $root, sub { die } ), $prop,
        'Propagator does nothing';

    is $carrier, {}, 'Nothing injected to carrier';

    ref_is $prop->extract( $carrier, $root, sub { die } ), $root,
        'Propagator does nothing';

    is [ $prop->keys ], [], 'No keys';
};

done_testing;
