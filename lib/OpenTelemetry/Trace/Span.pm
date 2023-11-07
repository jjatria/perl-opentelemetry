use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A single operation within a trace

package OpenTelemetry::Trace::Span;

use OpenTelemetry::Trace::SpanContext;

our $VERSION = '0.014';

class OpenTelemetry::Trace::Span {
    field $context :param :reader //= OpenTelemetry::Trace::SpanContext->new;

    method add_event ( %args ) { $self }

    method end ( $timestamp = time ) { $self }

    method record_exception ( $exception, %attributes ) { $self }

    method recording { 0 }

    method set_attribute ( %args ) { $self }

    method set_name ( $name ) { $self }

    method set_status ( $status, $description = '' ) { $self }
}

use constant {
    INVALID => OpenTelemetry::Trace::Span->new(
        context => OpenTelemetry::Trace::SpanContext::INVALID,
    ),
};

1;
