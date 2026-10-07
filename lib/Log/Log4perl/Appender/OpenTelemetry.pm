package Log::Log4perl::Appender::OpenTelemetry;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.031';

our @ISA = qw(Log::Log4perl::Appender);

use OpenTelemetry qw( otel_config otel_span_from_context otel_logger_provider );
use Ref::Util 'is_hashref';
use Time::HiRes 'time';

use OpenTelemetry::Constants qw(
    LOG_LEVEL_TRACE
    LOG_LEVEL_DEBUG
    LOG_LEVEL_INFO
    LOG_LEVEL_WARN
    LOG_LEVEL_ERROR
    LOG_LEVEL_FATAL
);

my %LOG2OTEL = (
    TRACE => LOG_LEVEL_TRACE,
    DEBUG => LOG_LEVEL_DEBUG,
    INFO  => LOG_LEVEL_INFO,
    WARN  => LOG_LEVEL_WARN,
    ERROR => LOG_LEVEL_ERROR,
    FATAL => LOG_LEVEL_FATAL,
);

my %OTEL2LOG = (
    TRACE => 8,
    DEBUG => 7,
    INFO  => 6,
    WARN  => 4,
    ERROR => 3,
    FATAL => 2,
);

sub new ($class, %params) {
    my $self =  {};
    bless $self, $class;
}

sub log ( $self, %params ) {
    #%params is
    #    { name    => $appender_name,
    #      level   => loglevel
    #      message => $message,
    #      log4p_category => $category,
    #      log4p_level  => $level,);
    #    },
    my $level = $params{log4p_level};
    otel_logger_provider->logger->emit_record(
        timestamp       => time,
        severity_text   => $level,
        severity_number => 0+$LOG2OTEL{$level},
        body            => $params{message},
    );
}

1;
