use Object::Pad;
# ABSTRACT: The abstract interface for OpenTelemetry log record processors

package OpenTelemetry::Logs::LogRecord::Processor;

our $VERSION = '0.029';

role OpenTelemetry::Logs::LogRecord::Processor :does(OpenTelemetry::Processor) {
    method on_emit;
}
