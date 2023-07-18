#!/usr/bin/env perl

use Test2::V0;

use Class::Inspector;

# Not using Test2::Require::Module because it loads the module when checking
skip_all 'Module HTTP::Tiny is not installed'
    unless Class::Inspector->installed('HTTP::Tiny');

use Log::Any::Adapter;
Log::Any::Adapter->set( { lexically => \my $scope }, Capture => to => \my @logs );

require OpenTelemetry::Integration;

subtest 'Load all plugins' => sub {
    @logs = ();
    OpenTelemetry::Integration->import(':all');

    is \@logs, [
        [
            trace => 'OpenTelemetry',
           'Loading OpenTelemetry::Integration::HTTP::Tiny',
        ],
    ];

    is + Class::Inspector->loaded('HTTP::Tiny'), F,
        'Did not load dependency automatically';
};

subtest 'Load a good plugin by name' => sub {
    @logs = ();
    OpenTelemetry::Integration->import('HTTP::Tiny');

    is \@logs, [
        [
            trace => 'OpenTelemetry',
            'Loading OpenTelemetry::Integration::HTTP::Tiny',
        ],
    ];

    is + Class::Inspector->loaded('HTTP::Tiny'), T,
        'Loaded dependency automatically';
};

subtest 'Load a missing plugin' => sub {
    @logs = ();
    OpenTelemetry::Integration->import('Fake::Does::Not::Exist');

    is \@logs, [
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
