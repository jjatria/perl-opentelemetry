#!/usr/bin/env perl

use Test2::V0;

use Scalar::Util 'refaddr';
use OpenTelemetry::Baggage;
use OpenTelemetry::Baggage::Propagation::TextMap;
use OpenTelemetry::Context::Propagation::Composite;

my $root = OpenTelemetry::Context->current;
my $ctxt = OpenTelemetry::Baggage->set( foo => 123, 'META', $root );

is $ctxt, object {
    prop isa => 'OpenTelemetry::Context';
    validator refaddr => sub { refaddr $_ != refaddr $root };
}, 'Setting baggage key returns new context';

my $carrier = {};
my $prop = OpenTelemetry::Context::Propagation::Composite->new(
    OpenTelemetry::Baggage::Propagation::TextMap->new,
);

is refaddr $prop->inject( $carrier, $ctxt ), refaddr $prop,
    'Inject returns self';

is $carrier->{baggage}, 'foo=123;META', 'Baggage injected into carrier';

done_testing;
