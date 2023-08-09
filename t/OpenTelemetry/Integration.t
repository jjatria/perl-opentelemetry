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

    OpenTelemetry::Integration->unimport;
};

subtest 'Falsy arguments to import' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import( '', undef );
    is + OpenTelemetry::Test::Logs->messages, [], 'No messages logged';

    OpenTelemetry::Integration->unimport;
};

subtest 'Load all plugins' => sub {
    OpenTelemetry::Test::Logs->clear;
    OpenTelemetry::Integration->import(':all');

    is + OpenTelemetry::Test::Logs->messages, bag {
        item [
            trace => 'OpenTelemetry',
           'Loading OpenTelemetry::Integration::HTTP::Tiny',
        ];
        item [
            trace => 'OpenTelemetry',
           'OpenTelemetry::Integration::HTTP::Tiny did not install itself',
        ];
        item [
            trace => 'OpenTelemetry',
           'Loading OpenTelemetry::Integration::DBI',
        ];
        item [
            trace => 'OpenTelemetry',
           'OpenTelemetry::Integration::DBI did not install itself',
        ];
        end;
    }, 'Did not install anything because dependencies were not loaded';

    is + Class::Inspector->loaded('HTTP::Tiny'), F,
        'Did not load HTTP::Tiny automatically';

    is + Class::Inspector->loaded('DBI'), F,
        'Did not load DBI automatically';

    OpenTelemetry::Integration->unimport;
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

    OpenTelemetry::Integration->unimport;
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

    OpenTelemetry::Integration->unimport;
};

done_testing;
