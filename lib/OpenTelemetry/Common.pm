package
    OpenTelemetry::Common;

# ABSTRACT: Utility package with shared functions for OpenTelemetry

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC );
use List::Util qw( any first );
use Ref::Util qw( is_arrayref is_hashref );

use namespace::clean;

use parent 'Exporter';

our @EXPORT_OK = qw(
    timeout_timestamp
    maybe_timeout
    config
    validate_attribute_value
);

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

sub timeout_timestamp :prototype() {
    clock_gettime CLOCK_MONOTONIC;
}

sub maybe_timeout ( $timeout = undef, $start = undef ) {
    return unless defined $timeout;

    $timeout -= ( timeout_timestamp - ( $start // 0 ) );

    $timeout > 0 ? $timeout : 0;
}

# As per https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md
sub config ( @keys ) {
    return unless @keys;

    my ($value) = first { defined && length } @ENV{
        map { 'OTEL_PERL_' . $_, 'OTEL_' . $_ } @keys
    };

    return $value unless defined $value;

    $value =~ /^true$/i ? 1 : $value =~ /^false$/i ? 0 : $value;
}

sub validate_attribute_value ( $value ) {
    if ( is_hashref $value ) {
        $logger->warnf('Span attribute values cannot be hash references');
        return;
    }

    if ( is_arrayref $value && any { ref } @$value ) {
        $logger->warnf('Span attribute values that are lists cannot hold references');
        return;
    }

    $value;
}

{
    my $error_handler;
    sub error_handler ( $, $handler = undef ) {
        $error_handler = $handler if $handler;
        return $error_handler //= sub (%args) {
            my $error = join ' - ', grep defined, @args{qw( exception message )};
            $logger->error("OpenTelemetry error: $error");
        };
    }
}

1;
