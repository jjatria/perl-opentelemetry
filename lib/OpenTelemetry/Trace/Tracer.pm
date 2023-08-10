use Object::Pad;
# ABSTRACT: A span factory for OpenTelemetry

package OpenTelemetry::Trace::Tracer;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::Tracer {
    use Feature::Compat::Defer;
    use Feature::Compat::Try;
    use Syntax::Keyword::Dynamically;
    use Ref::Util 'is_coderef';

    use OpenTelemetry::Constants 'SPAN_STATUS_ERROR';
    use OpenTelemetry::Context;
    use OpenTelemetry::Trace::Span;
    use OpenTelemetry::Trace;

    method create_span ( %args ) {
        OpenTelemetry::Trace::Span::INVALID;
    }

    # Experimental
    method in_span {
        my $block = pop;
        my $name  = shift;
        my %args  = @_;
        $args{name} = $name;

        unless ( is_coderef $block ) {
            $logger->warn('Missing required code block in call to Tracer->in_span');
            return $self;
        }

        my $span = $self->create_span(
            %args,
            parent => OpenTelemetry::Context->current
        );

        defer { $span->end };

        my $context = OpenTelemetry::Trace->context_with_span($span);

        dynamically OpenTelemetry::Context->current = $context;

        try {
            $block->( $span, $context );
        }
        catch ($e) {
            $span->record_exception($e);
            $span->set_status( SPAN_STATUS_ERROR, "$e" );
            die $e;
        }

        $self;
    }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace::Tracer - A span factory for OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry;

    my $provider = OpenTelemetry->tracer_provider;
    my $tracer   = $provider->tracer;

    # Create a span for manual use
    my $span = $tracer->create_span(%args);

    # Or execute code within a span (experimental)
    $tracer->in_span( my_span => sub ( $span, $context ) {
        ...
    });

=head1 DESCRIPTION

A tracer is responsible for creating L<OpenTelemetry::Trace::Span> objects.

=head1 METHODS

=head2 create_span

    $span = $tracer->create_span(
        name       => $name,      // 'empty',
        parent     => $context    // undef,
        kind       => $span_kind  // $internal,
        attributes => $attributes // {},
        links      => $links      // [],
        start      => $timestamp  // time,
    )

Creates an L<OpenTelemetry::Trace::Span> instance associated with this trace.

Takes a list of key / value pairs. Of these, the only one that callers are
I<always> expected to provide is the span name: not doing so may result in
a warning being logged and a placeholder name will be used instead. All other
keys are optional and can be used to further specify the span.

Note that even though the majority of these can be set after a span's
creation, it's always recommended to set these on creation if possible, since
this is the only time when they are guaranteed to be available for any
behaviours that may depend on them (eg. span sampling).

Spans can have zero or more child spans, which represent causally related
operations. These can be created by passing a
L<OpenTelemetry::Context> that holds the parent span as the value for the
C<parent> parameter. If no parent is set, or if the provided context does not
contain a span, the created span is considered a I<root span>. Typically, a
trace will only have one root span.

Spans can also have links to other spans, including those that belong to a
different trace. These can be set on span creation via the C<links> parameter,
which must hold a reference to an array of hashes, each of which should
be usable (when dereferenced) as the parameters to the span's
L<add_link|OpenTelemetry::Trace::Span/add_link> method.

It is the responsibility of the user to make sure that every span that has
been created is ended (via a call to its L<end|OpenTelemetry::Trace::Span/end>
method).

=head2 in_span

    # Experimental
    $tracer = $tracer->in_span(
        $span_name => sub ( $span, $context ) { ... },
        %span_arguments,
    );

This method is currently experimental.

Takes a string and a subroutine reference, and executes the code in that
reference within a span with that name. The subroutine reference will receive
the created span and the current context (containing the span) as arguments.
The span is guaranteed to be ended after execution of the subroutine ends by
any means.

Any additional parameters passed to this method will be passed as-is to the
call to L<create_span|/create_span> made when creating the span. Note that the
name provided before the subroutine reference is mandatory and will take
precedence over any name set in these additional parameters.

This method is chainable.

=head1 COPYRIGHT AND LICENSE

...
