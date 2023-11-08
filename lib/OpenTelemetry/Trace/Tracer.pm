use Object::Pad;
# ABSTRACT: A span factory for OpenTelemetry

package OpenTelemetry::Trace::Tracer;

our $VERSION = '0.014';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::Tracer {
    use Feature::Compat::Try;
    use Syntax::Keyword::Dynamically;
    use Ref::Util 'is_coderef';

    use OpenTelemetry::Constants 'SPAN_STATUS_ERROR';
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

        try {
            return $block->( $span, $context );
        }
        catch ($e) {
            $span->record_exception($e);

            my ($message) = split /\n/, "$e", 2;

            $span->set_status(
                SPAN_STATUS_ERROR, $message =~ s/ at \S+ line \d+\.$//r
            );

            die $e;
        }
        finally {
            $span->end;
        }
    }
}
