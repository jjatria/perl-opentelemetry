use Object::Pad;
# ABSTRACT: The abstract interface for OpenTelemetry exporters

package OpenTelemetry::Exporter;

our $VERSION = '0.017';

role OpenTelemetry::Exporter {
    method export;
    method shutdown;
    method force_flush;
}
