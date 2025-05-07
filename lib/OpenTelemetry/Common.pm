package
    OpenTelemetry::Internal::Logger;

use Carp::Clan '^(?:OpenTelemetry\b|Log::Any::Proxy$)';
use parent 'Log::Any::Adapter::Stderr';

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};

        # NOTE: We are using Carp::Clan so we carp from non-OTel
        # classes, but Carp::Clan for some reason likes to prepend
        # sub names, which we don't want
        local $SIG{__WARN__} = sub { warn shift =~ s/^.*?: //r };

        carp "$text";
    };
}

package
    OpenTelemetry::Common;

# ABSTRACT: Utility package with shared functions for OpenTelemetry

our $VERSION = '0.031';

use strict;
use warnings;
use experimental 'signatures';

use Bytes::Random::Secure ();
use List::Util qw( any first );
use OpenTelemetry::Constants qw( INVALID_TRACE_ID INVALID_SPAN_ID );
use Ref::Util qw( is_arrayref is_hashref );
use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC );

use parent 'Exporter';

our @EXPORT_OK = qw(
    config
    generate_span_id
    generate_trace_id
    maybe_timeout
    timeout_timestamp
    internal_logger
);

use Log::Any;
my $logger = Log::Any->get_logger(
    category => 'OpenTelemetry',
    $ENV{LOG_ANY_DEFAULT_ADAPTER} ? () : (
        default_adapter => [
            '+OpenTelemetry::Internal::Logger',
            log_level => $ENV{OTEL_PERL_INTERNAL_LOG_LEVEL} // 'warn',
        ],
    ),
);

# Undocumented because this is really only for internal use
sub internal_logger { $logger }

sub timeout_timestamp :prototype() {
    clock_gettime CLOCK_MONOTONIC;
}

sub maybe_timeout ( $timeout = undef, $start = undef ) {
    return unless defined $timeout;

    $timeout -= ( timeout_timestamp - ( $start // 0 ) );

    $timeout > 0 ? $timeout : 0;
}

# As per https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
sub config ( @keys ) {
    return unless @keys;

    my ($value) = first { defined && length } @ENV{
        map { 'OTEL_PERL_' . $_, 'OTEL_' . $_ } @keys
    };

    return $value unless defined $value;

    $value =~ /^true$/i ? 1 : $value =~ /^false$/i ? 0 : $value;
}

# Trace functions
sub generate_trace_id {
    while (1) {
        my $id = Bytes::Random::Secure::random_bytes 16;
        return $id unless $id eq INVALID_TRACE_ID;
    }
}

sub generate_span_id {
    while (1) {
        my $id = Bytes::Random::Secure::random_bytes 8;
        return $id unless $id eq INVALID_SPAN_ID;
    }
}

delete $OpenTelemetry::Common::{$_} for qw(
    CLOCK_MONOTONIC
    INVALID_SPAN_ID
    INVALID_TRACE_ID
    any
    clock_gettime
    first
    is_arrayref
    is_hashref
);

1;
