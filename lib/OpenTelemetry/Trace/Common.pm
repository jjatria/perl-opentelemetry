# This package is not indexed, since it's only a separate
# package to break an import cycle between
package
    OpenTelemetry::Trace::Common;

# ABSTRACT: The OpenTelemetry Span abstract interface

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use constant {
    INVALID_TRACE_ID => "\0" x 16,
    INVALID_SPAN_ID  => "\0" x  8,
};

use constant {
    HEX_INVALID_TRACE_ID => unpack('H*', INVALID_TRACE_ID),
    HEX_INVALID_SPAN_ID  => unpack('H*', INVALID_SPAN_ID),
};

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
