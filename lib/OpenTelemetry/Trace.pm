package OpenTelemetry::Trace;
# ABSTRACT: Generic methods for the OpenTelemetry Tracing API

our $VERSION = '0.011';

use strict;
use warnings;
use experimental 'signatures';

use OpenTelemetry::Common;
use OpenTelemetry::Context;
use OpenTelemetry::Trace::Span;

my $current_span_key = OpenTelemetry::Context->key('current-span');

sub span_from_context ( $, $context = undef ) {
    $context //= OpenTelemetry::Context->current;
    $context->get( $current_span_key ) // OpenTelemetry::Trace::Span::INVALID;
}

sub context_with_span ( $, $span, $context = undef ) {
    $context //= OpenTelemetry::Context->current;
    $context->set( $current_span_key => $span );
}

sub non_recording_span ( $, $context = undef ) {
    OpenTelemetry::Trace::Span->new( context => $context );
}

sub generate_trace_id { goto \&OpenTelemetry::Common::generate_trace_id }
sub generate_span_id  { goto \&OpenTelemetry::Common::generate_span_id  }

{
    my $untraced_key = OpenTelemetry::Context->key('untraced');
    sub untraced_context ( $, $context = undef ) {
        ( $context // OpenTelemetry::Context->current )->set( $untraced_key => 1 );
    }

    sub is_untraced_context ( $, $context = undef ) {
        !! ( $context // OpenTelemetry::Context->current )->get( $untraced_key );
    }
}

1;
