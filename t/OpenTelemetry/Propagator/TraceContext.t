#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext';

is CLASS->new, object {
    call_list keys => [qw( traceparent tracestate )];
};

done_testing;
