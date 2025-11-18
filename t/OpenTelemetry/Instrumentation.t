#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Instrumentation';
use Test2::Tools::OpenTelemetry;

use lib 't/lib';
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
            warning => 'OpenTelemetry',
            match qr/^Unable to load OpenTelemetry instrumentation for Fake::Does::Not::Exist: Can't locate/,
        ],
    ];

    CLASS->unimport;
};

subtest 'For package' => sub {
    is CLASS->for_package('HTTP::Tiny'), 'OpenTelemetry::Instrumentation::HTTP::Tiny',
        'Returns the package name of an available instrumentation library';

    is CLASS->for_package('Fake::Package'), U,
        'Returns undefined if there is no instrumentaiton';

    is CLASS->for_package(undef), U,
        'Garbage in, garbage out';

    is CLASS->for_package('Local::Only::Legacy'), 'OpenTelemetry::Integration::Local::Only::Legacy',
        'Falls back to legacy namespace if new is not available';
};

done_testing;
