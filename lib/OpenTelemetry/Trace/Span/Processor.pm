use Object::Pad;
# ABSTRACT: The abstract interface for OpenTelemetry span processors

package OpenTelemetry::Trace::Span::Processor;

our $VERSION = '0.033';

role OpenTelemetry::Trace::Span::Processor :does(OpenTelemetry::Processor) {
    method on_start;
    method on_end;
}
