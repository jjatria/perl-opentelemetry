# This package is not indexed, since it's only a separate
# package to break an import cycle
package
    OpenTelemetry::Trace::Common;

# ABSTRACT: Utility package with shared functions for OpenTelemetry tracing

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use OpenTelemetry::Constants qw( INVALID_TRACE_ID INVALID_SPAN_ID );
use Bytes::Random::Secure ();

sub generate_trace_id ( $ ) {
    while (1) {
        my $id = Bytes::Random::Secure::random_bytes 16;
        return $id unless $id eq INVALID_TRACE_ID;
    }
}

sub generate_span_id ( $ ) {
    while (1) {
        my $id = Bytes::Random::Secure::random_bytes 8;
        return $id unless $id eq INVALID_SPAN_ID;
    }
}

1;
