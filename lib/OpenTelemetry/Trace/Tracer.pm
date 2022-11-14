use Object::Pad;
# ABSTRACT: A no-op implementation of a Tracer

package OpenTelemetry::Trace::Tracer;

our $VERSION = '0.001';
use Object::Pad;

class OpenTelemetry::Trace::Tracer {
    use OpenTelemetry::Trace::Span;

    method create_span ( %args ) {
        OpenTelemetry::Trace::Span::INVALID;
    }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace::Tracer - A class that creates spans

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

A tracer is responsible for creating L<OpenTelemetry::Trace::Span> objects.

=head1 METHODS

=head2 create_span

    $span = $tracer->create_span(
        name       => $name,      # required
        parent     => $context    // undef,
        kind       => $span_kind  // $internal,
        attributes => $attributes // {},
        links      => $links      // [],
        start      => $timestamp  // time,
    )

Creates a L<OpenTelemetry::Trace::Span> instance associated with this trace.

Takes a list of key / value pairs including a mandatory span name. All other
keys are optional and can be used to further specify the span.

Note that even though the majority of these can be set after a span's
creation, it's always recommended to set these on creation if possible, since
this is the only time when they are guaranteed to be available for any
behaviours that may depend on them (eg. san sampling).

Spans can have zero or more child spans, which represent causally related
operations. These can be created via the C<parent> parameter, if it receives
a L<OpenTelemetry::Context> that holds a span. If no parent is set, or if the
provided context does not contain a span, the created span is considered a
I<root span>. Typically, a trace will only have one root span.

Spans can also have links to other spans, including those that belong to a
different trace. This can be set on span creation via the C<links> parameter,
which must hold a reference to an array of hashes, each of which should
be usable (when dereferenced) as the parameters to the span's
L<add_link|OpenTelemetry::Trace::Span/add_link> method.

It is the responsibility of the user to make sure that every span that has
been created is ended (via a call to its L<end|OpenTelemetry::Trace::Span/end>
method).

=head1 COPYRIGHT AND LICENSE

...
