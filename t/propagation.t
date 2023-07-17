#!/usr/bin/env perl

use Test2::V0;

use Scalar::Util 'refaddr';
use OpenTelemetry::Baggage;
use OpenTelemetry::Context::Propagation::Composite;
use OpenTelemetry::Propagator::Baggage;

my $context = OpenTelemetry::Baggage->set( foo => 123, 'META' );

my $carrier = {};
my $prop = OpenTelemetry::Context::Propagation::Composite->new(
    OpenTelemetry::Propagator::Baggage->new,
);

is refaddr $prop->inject( $carrier, $context ), refaddr $prop,
    'Inject returns self';

is $carrier->{baggage}, 'foo=123;META', 'Baggage injected into carrier';

done_testing;
