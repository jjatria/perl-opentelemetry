#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::TracerProvider';

use Scalar::Util 'refaddr';

is my $provider = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct a provider';

is my $tracer = $provider->tracer,
    object { prop isa => 'OpenTelemetry::Trace::Tracer' },
    'Can provide a tracer';

is refaddr $provider->tracer, refaddr $tracer,
    'Provided tracer is cached internally';

done_testing;
