#!/usr/bin/env perl

use Test2::V0;

use Class::Inspector;

# Not using Test2::Require::Module because it loads the module when checking
skip_all 'Module HTTP::Tiny is not installed'
    unless Class::Inspector->installed('HTTP::Tiny');

use OpenTelemetry::Test::Logs;

require OpenTelemetry::Integration;

subtest 'No arguments to import' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import;
    is + OpenTelemetry::Test::Logs->messages, [], 'No messages logged';
};

subtest 'Falsy arguments to import' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import( '', undef );
    is + OpenTelemetry::Test::Logs->messages, [], 'No messages logged';
};

subtest 'Load all plugins' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import(':all');

    is + OpenTelemetry::Test::Logs->messages, [
        [
            trace => 'OpenTelemetry',
           'Loading OpenTelemetry::Integration::HTTP::Tiny',
        ],
    ];

    is + Class::Inspector->loaded('HTTP::Tiny'), F,
        'Did not load dependency automatically';
};

subtest 'Load a good plugin by name' => sub {
    OpenTelemetry::Test::Logs->clear;

    OpenTelemetry::Integration->import('HTTP::Tiny');

    is + OpenTelemetry::Test::Logs->messages, [
        [
            trace => 'OpenTelemetry',
            'Loading OpenTelemetry::Integration::HTTP::Tiny',
        ],
    ];

    is + Class::Inspector->loaded('HTTP::Tiny'), T,
        'Loaded dependency automatically';
};

subtest 'Load a missing plugin' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import('Fake::Does::Not::Exist');

    is + OpenTelemetry::Test::Logs->messages, [
        [
            trace => 'OpenTelemetry',
            'Loading OpenTelemetry::Integration::Fake::Does::Not::Exist',
        ],
        [
            warning => 'OpenTelemetry',
            match qr/^Unable to load OpenTelemetry::Integration::Fake::Does::Not::Exist: Can't locate/,
        ],
    ];
};

done_testing;
