#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Event';
use Test2::Tools::OpenTelemetry;

is messages {
    is CLASS->new, object {
        call name       => 'empty';
        call attributes => hash { etc }; # Does this need a getter?
        call timestamp  => T;
    }, 'Can create an event';
} => [
    [ warning => OpenTelemetry => match qr/Missing name when creating .* event/ ],
];

done_testing;
