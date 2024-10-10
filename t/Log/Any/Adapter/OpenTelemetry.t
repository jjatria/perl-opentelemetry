#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;

use Object::Pad;
use OpenTelemetry ':all';
use Log::Any '$log';
use Log::Any::Adapter;

my @records;
class Local::LoggerProvider :isa(OpenTelemetry::Logs::LoggerProvider) {
    use Test2::V0;
    method logger ( %args ) {
        return mock obj => add => [
            emit_record => sub {
                shift; push @records => { @_ };
            },
        ];
    }
}

otel_logger_provider = Local::LoggerProvider->new;

Log::Any::Adapter->set('OpenTelemetry');

after_each Cleanup => sub {
    @records = ();
};

describe Levels => sub {
    my ( $level, $first );

    after_case Reset => sub { undef $first };

    case Trace => sub { $level = 'trace' };
    case Debug => sub { $level = 'debug' };
    case Info  => sub { $level = 'info'  };
    case Warn  => sub { $level = 'warn'  };
    case Error => sub { $level = 'error' };
    case Fatal => sub { $level = 'fatal' };
    case Bad   => sub { $level = 'bad'; $first = 'info' };

    it Works => { flat => 1 } => sub {
        local $ENV{OTEL_LOG_LEVEL} = $level;

        for my $method ( Log::Any->logging_methods ) {
            my $numeric = Log::Any::Adapter::Util::numeric_level($method);
            $log->$method($numeric)
        }

        my $want = Log::Any::Adapter::Util::numeric_level( $first // $level );
        is $records[0]->{body}, $want;
    }
};

describe Body => sub {
    my ( @args, $body, $attributes );

    case String => sub {
        @args = $body = 'string';
        $attributes = DNE;
    };

    case Hash => sub {
        @args = $body = { foo => 123 };
        $attributes = DNE;
    };

    case Array => sub {
        @args = ( body => [ foo => 122 ] );

        ( $body, my $rest ) = @args;
        $attributes = { payload => $rest };
    };

    case Attributes => sub {
        @args = (
            body => (
                foo => 123,
                bar => 234,
            ),
        );

        ( $body, my @rest ) = @args;
        $attributes = { @rest };
    };

    it Works => { flat => 1 } => sub {
        $log->info(@args);
        is \@records, [
            {
                body => $body,
                attributes => $attributes,
                severity_number => E,
                severity_text => 'info',
                timestamp => T,
            }
        ];
    };
};

done_testing;
