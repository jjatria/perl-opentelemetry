use Object::Pad;
# ABSTRACT: A context class for OpenTelemetry

package OpenTelemetry::Trace::Span;

use OpenTelemetry::Trace::Span::Context;

our $VERSION = '0.001';

class OpenTelemetry::Trace::Span does OpenTelemetry::Trace::Span::Role {
    has $context :param :reader = undef;

    ADJUST {
        $context //= OpenTelemetry::Trace::Span::Context->new;
    }

    method recording { 0 }
}

use constant INVALID => OpenTelemetry::Trace::Span->new(
    context => OpenTelemetry::Trace::Span::Context::INVALID(),
);

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

Returns the L<OpenTelemetry::Trace::Span::Context> object associated with this
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

=head1 COPYRIGHT AND LICENSE

...
