use Object::Pad;
# ABSTRACT: An abstract interface for OpenTelemetry propagators

package OpenTelemetry::Propagator;

our $VERSION = '0.023001';

role OpenTelemetry::Propagator {
    method extract;
    method inject;
    method keys;
}
