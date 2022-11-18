#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Event';

is CLASS->new, object {
    call name       => 'empty';
    call attributes => hash { etc }; # Does this need a getter?
    call timestamp  => T;
}, 'Can create an event';

done_testing;
