package Log::Any::Adapter::OpenTelemetry;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.031';

use Log::Any::Adapter::Util ();
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

use base 'Log::Any::Adapter::Base';

my %LOG2OTEL = (
    trace => LOG_LEVEL_TRACE,
    debug => LOG_LEVEL_DEBUG,
    info  => LOG_LEVEL_INFO,
    warn  => LOG_LEVEL_WARN,
    error => LOG_LEVEL_ERROR,
    fatal => LOG_LEVEL_FATAL,
);

my %OTEL2LOG = (
    trace => 8,
    debug => 7,
    info  => 6,
    warn  => 4,
    error => 3,
    fatal => 2,
);

sub init ( $self, @ ) {
    # FIXME: It would be good to get a logger early and cache
    # it for eventual calls. However, this suffers from the same
    # issue with caching tracers that is documented in the POD
    # for OpenTelemetry::Trace::Tracer: namely, that if we get
    # the no-op logger before we've set up a real logger provider
    # that can generate real loggers, we'll be stuck with a no-op.
    # It might be that we need to revisit the proxy classes removed
    # in d9e321bd1bf65d510b12ef34fe2b5a0c51da0bf2, although the
    # rationale for why they were removed is still sound. We'd just
    # have to come up with a way to make sure its delegate continues
    # to point to the right place even if the tracer provider changes
    # $self->{logger} = otel_logger_provider->logger;
}

for my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    *$method = sub ( $self, @args) {
        $self->structured( $method, $self->category, @args );
    };
}

for my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    my $numeric = Log::Any::Adapter::Util::numeric_level( $method =~ s/^is_//r );

    no strict 'refs';
    *$method = sub {
        my $level = $OTEL2LOG{ lc( otel_config('LOG_LEVEL') // 'info' ) };
        $numeric <= ( $level // $OTEL2LOG{info} );
    };
}

sub structured ( $self, $method, $category, @parts ) {
    my $level = $method;
    for ($level) {
        s/(?:emergency|alert|critical)/fatal/;
        s/notice/info/;
        s/warning/warn/;
    }

    # FIXME: This is a little finicky. The aim is for the first
    # argument to be the body (even if it is structured), and
    # anything else gets put into the attributes. If the log
    # comes with structured data that is not a hash, we put it
    # under a `payload` key. Maybe this can be simplified to
    # always put the data under a given key, but then we add
    # data to the arguably common operation of attaching a hash.
    my %args = ( body => shift @parts );

    $args{attributes} = @parts == 1
        ? is_hashref $parts[0]
            ? $parts[0] : { payload => $parts[0] }
        : @parts % 2
            ? { payload => \@parts } : { @parts }
        if @parts;

    otel_logger_provider->logger->emit_record(
        timestamp       => time,
        severity_text   => $method,
        severity_number => 0+$LOG2OTEL{$level},
        %args,
    );
}

1;
