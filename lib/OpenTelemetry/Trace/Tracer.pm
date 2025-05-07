use Object::Pad;
# ABSTRACT: A span factory for OpenTelemetry

package OpenTelemetry::Trace::Tracer;

our $VERSION = '0.031';

class OpenTelemetry::Trace::Tracer {
    use Feature::Compat::Try;
    use Syntax::Keyword::Dynamically;
    use Ref::Util 'is_coderef';

    use OpenTelemetry::Constants qw( SPAN_STATUS_ERROR SPAN_STATUS_OK );
    use OpenTelemetry::Context;
    use OpenTelemetry::Trace::Span;
    use OpenTelemetry::Trace;
    use OpenTelemetry::X;

    method create_span ( %args ) {
        OpenTelemetry::Trace::Span::INVALID;
    }

    # Experimental
    method in_span {
        is_coderef $_[-1] or die OpenTelemetry::X->create(
            Invalid => 'Missing required code block in call to Tracer->in_span',
        );

        my $block = pop;
        my $name  = shift;
        my %args  = @_;

        $args{name} = $name or die OpenTelemetry::X->create(
            Invalid => 'Missing required span name to Tracer->in_span',
        );

        my $span = $self->create_span(
            %args,
            parent => OpenTelemetry::Context->current
        );

        my $context = OpenTelemetry::Trace->context_with_span($span);

        dynamically OpenTelemetry::Context->current = $context;

        my ( $error );
        try {
            return $block->( $span, $context );
        }
        catch ($e) {
            $span->record_exception($e);

            ($error) = split /\n/, "$e", 2;
            $error =~ s/ at \S+ line \d+\.$//;

            die $e;
        }
        finally {
            $span->set_status(
                $error ? ( SPAN_STATUS_ERROR, $error ) : SPAN_STATUS_OK
            );

            $span->end;
        }
    }
}
