#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Logs::LoggerProvider';

is my $provider = CLASS->new, object {
    prop isa => $CLASS;
}, 'Can construct a provider';

is my $logger = $provider->logger,
    object { prop isa => 'OpenTelemetry::Logs::Logger' },
    'Can provide a logger';

ref_is $provider->logger, $logger,
    'Provided logger is cached internally';

done_testing;
