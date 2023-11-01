use Object::Pad;
# ABSTRACT: The abstract interface for OpenTelemetry span processors

package OpenTelemetry::Trace::Span::Processor;

our $VERSION = '0.012';

role OpenTelemetry::Trace::Span::Processor {
    method on_start;
    method on_end;

    method shutdown;
    method force_flush;
}
