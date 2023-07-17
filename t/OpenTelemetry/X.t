#!/usr/bin/env perl

use Test2::V0;

use OpenTelemetry::X;
use OpenTelemetry::X::Invalid;

is my $x = OpenTelemetry::X->create('Invalid'), object {
    prop isa => 'OpenTelemetry::X';
}, 'Created exceptions are children of OpenTelemetry::X';

like dies { $x->create('Invalid') },
    qr/OpenTelemetry::X::Invalid->create is not allowed.*OpenTelemetry::X->create/,
    'Only OpenTelemetry::X package can create excetpions';

done_testing;
