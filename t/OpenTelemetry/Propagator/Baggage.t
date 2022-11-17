#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::Baggage';

use Scalar::Util 'refaddr';
use OpenTelemetry::Baggage;
use OpenTelemetry::Propagator::Baggage;

my $carrier = {};

my $ctxt = OpenTelemetry::Baggage->set( foo => 123, 'META' );
my $prop = CLASS->new;

is refaddr $prop->inject( $carrier, $ctxt ), refaddr $prop,
    'Inject returns self';

is $carrier->{baggage}, 'foo=123;META', 'Baggage injected into carrier';

done_testing;
