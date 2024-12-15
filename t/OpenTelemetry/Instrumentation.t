#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Instrumentation';
use Test2::Tools::OpenTelemetry;

use Class::Inspector;

# Not using Test2::Require::Module because it loads the module when checking
skip_all 'Module HTTP::Tiny is not installed'
    unless Class::Inspector->installed('HTTP::Tiny');

subtest 'No arguments to import' => sub {
    no_messages { CLASS->import };
    CLASS->unimport;
};

subtest 'Falsy arguments to import' => sub {
    no_messages { CLASS->import( '', undef ) };
    CLASS->unimport;
};

subtest 'Load all plugins' => sub {
    is messages { CLASS->import(':all') } => bag {
        item [
            trace => 'OpenTelemetry',
           "Loading ${CLASS}::HTTP::Tiny",
        ];
        item [
            trace => 'OpenTelemetry',
           "${CLASS}::HTTP::Tiny did not install itself",
        ];
        item [
            trace => 'OpenTelemetry',
           "Loading ${CLASS}::DBI",
        ];
        item [
            trace => 'OpenTelemetry',
           "${CLASS}::DBI did not install itself",
        ];
        etc;
    }, 'Did not install anything because dependencies were not loaded';

    is + Class::Inspector->loaded('HTTP::Tiny'), F,
        'Did not load HTTP::Tiny automatically';

    is + Class::Inspector->loaded('DBI'), F,
        'Did not load DBI automatically';

    CLASS->unimport;
};

subtest 'Load a good plugin by name' => sub {
    is messages {
        CLASS->import('HTTP::Tiny');
    } => [
        [
            trace => 'OpenTelemetry',
            "Loading ${CLASS}::HTTP::Tiny",
        ],
    ];

    is + Class::Inspector->loaded('HTTP::Tiny'), T,
        'Loaded dependency automatically';

    CLASS->unimport;
};

subtest 'Load a missing plugin' => sub {
    is messages {
        CLASS->import('Fake::Does::Not::Exist');
    } => [
        [
            trace => 'OpenTelemetry',
            "Loading ${CLASS}::Fake::Does::Not::Exist",
        ],
        [
            warning => 'OpenTelemetry',
            match qr/^Unable to load ${CLASS}::Fake::Does::Not::Exist: Can't locate/,
        ],
    ];

    CLASS->unimport;
};

done_testing;
