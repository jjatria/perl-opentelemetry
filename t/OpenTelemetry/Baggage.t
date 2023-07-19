#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Baggage';

use OpenTelemetry::Context;

subtest 'No baggage' => sub {
    my $k = OpenTelemetry::Context->key('foo');
    my $context = OpenTelemetry::Context->current->set( $k => 123 );

    is + CLASS->get('foo'), U,
        '->get returns undef with no baggage';

    is + CLASS->get( foo => $context ), U,
        '->get returns undef with no baggage (explicit context)';

    is + CLASS->delete('foo'), object {
        call [ get => $k ] => U;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { ! defined CLASS->get('foo') };
    }, '->delete returns context without key';

    is + CLASS->delete( foo => $context ), object {
        call [ get => $k ] => 123;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { ! defined CLASS->get('foo') };
    }, '->delete returns context without key (explicit context)';

    is { CLASS->all }, {},
        '->all returns no pairs';

    is { CLASS->all($context) }, {},
        '->all returns no pairs (explicit context)';

    is + CLASS->clear, object {
        call [ get => $k ] => U;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { ! CLASS->all($_) };
    }, '->clear returns no pairs';

    is + CLASS->clear($context), object {
        call [ get => $k ] => 123;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { ! CLASS->all($_) };
    }, '->clear returns no pairs (explicit context)';

    is + CLASS->set( foo => 'ok' ), object {
        call [ get => $k ] => U;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { CLASS->get( foo => $_ )->value eq 'ok' };
    }, '->set returns context with key';

    is + CLASS->set( foo => 'ok', 'meta', $context ), object {
        call [ get => $k ] => 123;
        prop isa  => 'OpenTelemetry::Context';
        prop this => validator sub { CLASS->get( foo => $_ )->value eq 'ok' };
    }, '->set returns context with key (explicit context)';
};

subtest 'With baggage' => sub {
    my $context = CLASS->builder
        ->set( foo => 'ok', 'meta' )
        ->set( bar => 'ko' )
        ->build;

    my $deleted = CLASS->delete( foo => $context );
    my $cleared = CLASS->clear($context);

    is { CLASS->all($context) }, {
        foo => object {
            prop isa   => 'OpenTelemetry::Baggage::Entry';
            call value => 'ok';
            call meta  => 'meta';
        },
        bar => object {
            prop isa   => 'OpenTelemetry::Baggage::Entry';
            call value => 'ko';
            call meta  => U;
        },
    }, 'Set multiple keys';

    is { CLASS->all($deleted) }, {
        bar => object {
            prop isa   => 'OpenTelemetry::Baggage::Entry';
            call value => 'ko';
            call meta  => U;
        },
    }, 'Deleted single entry';

    is { CLASS->all($cleared) }, {}, 'No baggage after clear';
};

done_testing;
