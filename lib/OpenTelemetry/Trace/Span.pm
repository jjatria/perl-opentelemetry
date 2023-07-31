use Object::Pad;
# ABSTRACT: A single operation within a trace

package OpenTelemetry::Trace::Span;

use OpenTelemetry::Trace::SpanContext;
use OpenTelemetry::Trace::Span::Status;

our $VERSION = '0.001';

class OpenTelemetry::Trace::Span {
    has $context :param :reader = undef;

    ADJUST {
        $context //= OpenTelemetry::Trace::SpanContext->new;
    }

    method recording { 0 }

    method set_attribute ( %args ) { $self }

    method set_name ( $name ) { $self }

    method set_status ( $status, $description = '' ) { $self }

    method add_link ( %args ) { $self }

    method add_event ( %args ) { $self }

    method end ( $timestamp = time ) { $self }
}

use constant {
    INVALID => OpenTelemetry::Trace::Span->new(
        context => OpenTelemetry::Trace::SpanContext::INVALID,
    ),

    STATUS_UNSET => OpenTelemetry::Trace::Span::Status::UNSET,
    STATUS_OK    => OpenTelemetry::Trace::Span::Status::OK,
    STATUS_ERROR => OpenTelemetry::Trace::Span::Status::ERROR,

    KIND_INTERNAL => 1,
    KIND_SERVER   => 2,
    KIND_CLIENT   => 3,
    KIND_PRODUCER => 4,
    KIND_CONSUMER => 5,
};

use Exporter 'import';

our %EXPORT_TAGS = (
    kind => [qw(
        KIND_INTERNAL
        KIND_SERVER
        KIND_CLIENT
        KIND_PRODUCER
        KIND_CONSUMER
    )],
    status => [qw(
        STATUS_UNSET
        STATUS_OK
        STATUS_ERROR
    )],
);

our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace::Span - A single operation within a trace

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

An instance of this class represents a single operation within a trace.

Spans have a name that identifies them, and can store additional data
related to the operation they represent, including start and end timestamps
as well as other metadata (see the L<add_link|/add_link>,
L<add_event|/add_event>, and L<set_attribute|/set_attribute> methods below
for some ways in which this can be achieved).

Spans can also link to a parent L<OpenTelemetry::Context>, which allows them
to form a tree structure within a trace.

The only supported way to create a span is through an L<OpenTelemetry::Trace::Tracer>.
Refer to the L<create_span|OpenTelemetry::Trace::Tracer/create_span> method in
that class for details.

=head1 METHODS

=head2 context

    $span_context = $span->context

Returns the L<OpenTelemetry::Trace::SpanContext> object associated with this
span. This value can continue to be used even after the span is finished, and
is guaranteed to be the same throughout the entire lifetime of the span.

=head2 recording

    $bool = $span->recording

Returns a true value if the span is recording information like
L<events|/add_event>, L<attributes|/set_attribute>, L<status|/set_status>,
etc. This might be the case if eg. the span has been ended.

Note that the recording state of a span does not extend to any of its
children.

Note also that this method may return true even if the entire span has been
sampled out.

=head2 set_attribute

    $span = $span->set_attribute( $key => $value )
    $span = $span->set_attribute( %pairs )

Set one or more attributes in this span.

Setting an attribute will overwrite any attribute of the same name.

Refer to
L<the OpenTelementry specification|https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/README.md>
for details on some of the standard attribute names and their meanings.

This method returns the calling span, which means it can be chained.

=head2 add_event

    $span = $span->add_event(
        name       => $name       // 'undef',
        timestamp  => $timestamp  // time,
        attributes => $attributes // {},
    )

Add an event to this span.

Refer to
L<the OpenTelementry specification|https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/README.md>
for details on some of the standard event names and their meanings.

This method returns the calling span, which means it can be chained.

=head2 add_link

    $span = $span->add_link(
        context    => $span_context,
        attributes => $attributes   // {},
    )

Add a link to this span.

A span may be linked to zero or more spans that are causally related, even if
these spans belong to a different trace. Links can be used to represent
batched operations where a Span was initiated by multiple initiating Spans,
each representing a single incoming item being processed in the batch.

This method returns the calling span, which means it can be chained.

=head2 set_status

    $span = $span->set_status( $status, $description // '' )

Sets the status of a span.

Every span starts with an "unset" status. This can be changed to either an
"Ok" status, which indicates the operation represented by this span is deemed
to have completed successfully; or "Error", in which case the operation did
not.

A span's status can only be set: any attempt to unset it will be ignored.
Likewise, an "Ok" status is final, and any attempts to alter it will also be
ignored.

This method returns the calling span, which means it can be chained.

=head2 set_name

    $span = $span->set_name( $name )

Sets the name a span. This name will override whatever name was used during
creation.

This method returns the calling span, which means it can be chained.

=head2 end

    $span = $span->end( $timestamp // time )

Marks the span as ended. This will most commonly mean that the span is no
longer L<recording|/recording>.

Note that ending a span does not, by itself, affect any of the span's child
spans. It also does not render the span invalid or limit its capacity to be
used to create new child spans.

This method returns the calling span, which means it can be chained.

=head1 CONSTANTS

=head2 INVALID

Stores a span with an invalid L<OpenTelemetry::Trace::SpanContext>. This will
be sometimes returned to mark the lack of a valid span, while still providing
an instance on which methods can be called.

=head2 Span status codes

These can be exported individually, or with the C<:status> tag.

=over

=item STATUS_UNSET

The status of a span when no status has been set. This is the default value.

=item STATUS_OK

The status of a span that has been marked as having completed successfully by
an application.

=item STATUS_ERROR

The status of a span that has been marked as not having completed successfully
by an application.

=back

=head2 Span kinds

These constants are used to specify the type of the span. They can be exported
individually, or with the C<:kind> tag.

=over

=item KIND_INTERNAL

The span is internal to an application, and is not at one of its boundaries
(eg. with other applications). If no kind is specified, this is the default
value.

=item KIND_SERVER

The span covers the server-side handling of some remote network request.

=item KIND_CLIENT

The span describes a request to a remote service.

=item KIND_PRODUCER

The span describes a message sent to a broker. Unlike the client and server
kinds above, the action represented by this span ends once the broker accepts
the message, even if the logical processing of that message can take longer.

=item KIND_CONSUMER

The span describes a consumer receiving a message from a broker.

=back

=head1 COPYRIGHT AND LICENSE

...
