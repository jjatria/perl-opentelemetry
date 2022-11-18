#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Link';

use Scalar::Util 'refaddr';
use OpenTelemetry::Trace::SpanContext;

my $context = OpenTelemetry::Trace::SpanContext::INVALID;

is CLASS->new( context => $context ), object {
    call attributes => hash { etc }; # Does this need a getter?
    call context    => validator sub { refaddr $_ == refaddr $context };
}, 'Can create a link';

like dies { CLASS->new },
    qr/^Required parameter 'context' is missing/,
    'Requires a context';

like dies { CLASS->new( context => mock ) },
    qr/^Required parameter 'context' must be a span context/,
    'Validates context';

done_testing;
