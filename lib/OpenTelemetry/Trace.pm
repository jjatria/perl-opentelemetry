package OpenTelemetry::Trace;
# ABSTRACT: Generic methods for the OpenTelemetry Tracing API

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use Exporter 'import';

use constant {
    EXPORT_SUCCESS => 0,
    EXPORT_FAILURE => 1,
    EXPORT_TIMEOUT => 2,
};

use OpenTelemetry::Context;
use OpenTelemetry::Trace::Span;
use OpenTelemetry::Trace::Common;

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

sub generate_trace_id { goto \&OpenTelemetry::Trace::Common::generate_trace_id }
sub generate_span_id  { goto \&OpenTelemetry::Trace::Common::generate_span_id  }
sub INVALID_TRACE_ID  { goto \&OpenTelemetry::Trace::Common::INVALID_TRACE_ID  }
sub INVALID_SPAN_ID   { goto \&OpenTelemetry::Trace::Common::INVALID_SPAN_ID   }

# Exports

our %EXPORT_TAGS = (
    constants => [qw(
        EXPORT_FAILURE
        EXPORT_SUCCESS
        EXPORT_TIMEOUT
        INVALID_SPAN_ID
        INVALID_TRACE_ID
    )],
);

our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

1;

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace - Generic methods for the OpenTelemetry Tracing API

=head1 SYNOPSIS

    use OpenTelemetry::Trace;

    # Retrieve a span from context
    my $span = OpenTelemetry::Trace->span_from_context;

    # Store a span in the context
    my $context = OpenTelemetry::Trace->context_with_span($span);

    # This is a no-op, since we are retrieving the span we stored
    $span = OpenTelemetry::Trace->span_from_context($context);

=head1 DESCRIPTION

This package provides some methods for injecting L<Span> objects into, and
extracting them from, a given L<context|OpenTelemetry::Context>.

For the meat and bones of the OpenTelemetry Tracing API, please see the
following packages:

=over

=item L<OpenTelemetry::Trace::TracerProvider>, which provides access to
      L<tracers|OpenTelemetry::Trace::Tracer>.

=item L<OpenTelemetry::Trace::Tracer>, which can create
      L<spans|OpenTelemetry::Trace::Span>.

=item L<OpenTelemetry::Trace::Span>, which allows the trace of a single
      operation.

=back

=head1 METHODS

=head2 span_from_context

    $span = OpenTelemetry::Trace->span_from_context($context);

Takes an optional L<OpenTelemetry::Context> object, and returns the
L<OpenTelemetry::Trace::Span> object that has been stored within, if any. If
no context was provided, the span will be read from the current context.

If no span was found in the context, this method returns an invalid span
(see L<below|/INVALID_SPAN_ID>).

=head2 context_with_span

    $context = OpenTelemetry::Trace->context_with_span( $span, $context );

Takes a L<OpenTelemetry::Trace::Span> and returns a context that contains it
(such that passing that context to eg. L<span_from_context|/span_from_context>
would return the provided span).

An optional L<OpenTelemetry::Context> instance can be passed as a second
argument, in which case it will be used as the base for the new context. If no
context is provided, the L<current context|OpenTelemetry::Context/current>
will be used.

=head2 non_recording_span

    $span = OpenTelemetry::Trace->non_recording_span($span_context)

Returns an instance of L<OpenTelemetry::Trace::Span> that records no trace
data. Operations on this span are effectively a no-op.

Takes an instance of L<OpenTelemetry::Trace::SpanContext> to use as the
context of the span. If none is provided, it will default to a new instance.

=head2 generate_trace_id

    $id = OpenTelemetry::Trace->generate_trace_id;

Generate a new random trace ID. This ID is guaranteed to be valid.

=head2 generate_span_id

    $id = OpenTelemetry::Trace->generate_span_id;

Generate a new random span ID. This ID is guaranteed to be valid.

=head1 CONSTANTS

These can be exported on request, or as a set with the C<:constants> export
tag.

=head2 EXPORT_SUCCESS

Marks an export operation as a success.

=head2 EXPORT_FAILURE

Marks an export operation as a failure.

=head2 EXPORT_TIMEOUT

Marks an export operation that was interrupted because it took too long.

=head2 INVALID_SPAN_ID

    $null = OpenTelemetry::Trace::INVALID_SPAN_ID;

Returns a constant ID that can be used to identify an invalid span.

=head2 INVALID_TRACE_ID

    $null = OpenTelemetry::Trace::INVALID_TRACE_ID;

Returns a constant ID that can be used to identify an invalid trace.

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Trace::TracerProvider>

=item L<OpenTelemetry::Trace::Tracer>

=item L<OpenTelemetry::Trace::Span>

=back

=head1 COPYRIGHT AND LICENSE

...
