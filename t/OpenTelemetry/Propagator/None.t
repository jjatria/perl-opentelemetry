#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::None';

use OpenTelemetry::Test::Logs;
use OpenTelemetry::Context;

my $root = OpenTelemetry::Context->current;

my $carrier = {};

is my $prop = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct propagator';

ref_is $prop->inject( $carrier, $root, sub { die } ), $prop,
    'Propagator does nothing';

is $carrier, {}, 'Nothing injected to carrier';

ref_is $prop->extract( $carrier, $root, sub { die } ), $root,
    'Propagator does nothing';

is [ $prop->keys ], [], 'No keys';

is + OpenTelemetry::Test::Logs->messages, [], 'Nothing logged';

done_testing;
