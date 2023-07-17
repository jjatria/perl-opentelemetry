#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Propagator::TraceContext::TraceState';

use Log::Any::Adapter;

subtest Parsing => sub {
    my $test = CLASS->from_string('rojo=00f067aa0ba902b7,congo=t61rcWkgMzE');

    is $test, object {
        call [ get => 'rojo'  ] => '00f067aa0ba902b7';
        call [ get => 'congo' ] => 't61rcWkgMzE';
    }, 'Can parse TraceState string';

    is $test->to_string, 'rojo=00f067aa0ba902b7,congo=t61rcWkgMzE',
        'Can generate TraceState string';

    is CLASS->from_string(' foo=123 ,, bar=234 ')->to_string,
        'foo=123,bar=234',
        'Drops surrounding spaces and empty members';

    is CLASS->from_string('foo=with spaces')->to_string,
        'foo=with spaces',
        'Keeps spaces inside values';

    is CLASS->from_string(''), D, 'Can parse empty string';
    is CLASS->from_string(undef), D, 'Ignores undefined string';

    is CLASS->from_string('ok=1,this=or=that,!=123')->to_string, 'ok=1',
        'Ignores bad keys and values';

    is CLASS->from_string('test@cpan=timtowtdi'), object {
        call [ get => 'test@cpan' ] => 'timtowtdi';
    }, 'Accepts multi-tenant keys';
};

subtest Modification => sub {
    my $test = CLASS->from_string('rojo=00f067aa0ba902b7,congo=t61rcWkgMzE');

    is $test->set( new => 'deadbeef' )->to_string,
        'new=deadbeef,rojo=00f067aa0ba902b7,congo=t61rcWkgMzE',
        'Newly set members appear on left';

    is $test->to_string,
        'rojo=00f067aa0ba902b7,congo=t61rcWkgMzE',
        'TraceState is immutable';

    is $test->delete('congo')->to_string,
        'rojo=00f067aa0ba902b7',
        'Can delete members';

    is $test->delete('xxx')->to_string,
        'rojo=00f067aa0ba902b7,congo=t61rcWkgMzE',
        'Deleting missing field does nothing';

    is $test->set( congo => 'deadbeef' )->to_string,
        'congo=deadbeef,rojo=00f067aa0ba902b7',
        'Setting an existing key overwrites';

    is $test->get('congo'), 't61rcWkgMzE', 'Can read values';
    is $test->get('xxx'), U, 'Reading missing values returns undefined';

    subtest 'Invalid key / value' => sub {
        Log::Any::Adapter->set(
            { lexically => \my $scope },
            Capture => to => \my @messages,
        );

        my $test = CLASS->from_string('foo=123');

        is $test->set( '' => 123 )->to_string, 'foo=123', 'Ignore empty key';
        is $test->set( 'òó' => 1 )->to_string, 'foo=123', 'Ignore invalid key';

        is $test->set( 'x' => "" )->to_string, 'foo=123',   'Ignore empty value';
        is $test->set( 'x' => "," )->to_string, 'foo=123',  'Comma not a valid value';
        is $test->set( 'x' => "\t" )->to_string, 'foo=123', 'Tab not a valid value';
        is $test->set( 'x' => "\n" )->to_string, 'foo=123', 'Newline not a valid value';
        is $test->set( 'x' => "\r" )->to_string, 'foo=123', 'Carriage return not a valid value';

        is \@messages, [
            [ debug => OpenTelemetry => "Invalid TraceState member key: '' => '123'" ],
            [ debug => OpenTelemetry => "Invalid TraceState member key: 'òó' => '1'" ],
            [ debug => OpenTelemetry => "Invalid TraceState member value: 'x' => ''" ],
            [ debug => OpenTelemetry => "Invalid TraceState member value: 'x' => ','" ],
            [ debug => OpenTelemetry => "Invalid TraceState member value: 'x' => '\t'" ],
            [ debug => OpenTelemetry => "Invalid TraceState member value: 'x' => '\n'" ],
            [ debug => OpenTelemetry => "Invalid TraceState member value: 'x' => '\r'" ],
        ], 'Log invalid key / value pairs';
    };
};

done_testing;
