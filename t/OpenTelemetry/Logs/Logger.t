#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Logs::Logger';
use Test2::Tools::OpenTelemetry;

is my $logger = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct logger';

is $logger->emit_record( body => 'foo' ), U,
    'Emit record returns nothing';

done_testing;
