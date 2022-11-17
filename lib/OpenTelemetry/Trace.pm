package OpenTelemetry::Trace;
# ABSTRACT: The OpenTelemetry Span abstract interface

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use OpenTelemetry::Context;
use OpenTelemetry::Trace::Span;
use OpenTelemetry::Trace::Common;

my $current_span_key = OpenTelemetry::Context->key('current-span');

sub span_from_context ( $, $context = OpenTelemetry::Context->current ) {
    $context->get( $current_span_key ) // OpenTelemetry::Trace::Span::INVALID;
}

sub context_with_span ( $, $span, $context = OpenTelemetry::Context->current ) {
    $context->set( $current_span_key => $span );
}

sub non_recording_span ( $, $context ) {
    OpenTelemetry::Trace::Span->new( context => $context );
}

sub generate_trace_id { goto \&OpenTelemetry::Trace::Common::generate_trace_id }
sub generate_span_id  { goto \&OpenTelemetry::Trace::Common::generate_span_id  }
sub INVALID_TRACE_ID  { goto \&OpenTelemetry::Trace::Common::INVALID_TRACE_ID  }
sub INVALID_SPAN_ID   { goto \&OpenTelemetry::Trace::Common::INVALID_SPAN_ID   }

1;
