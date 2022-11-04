#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span';

subtest 'Span creation' => sub {
    my $span = CLASS->new( name => 'foo' );

    is $span, object { prop isa => CLASS };

    is $span->set_name('bar'), object { prop isa => CLASS },
        'Setting span name is chainable';

    is $span->set_attribute( key => 123 ), object { prop isa => CLASS },
        'Setting span attribute is chainable';
};

done_testing;
