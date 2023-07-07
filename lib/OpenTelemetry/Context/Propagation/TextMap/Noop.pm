use Object::Pad;
# ABSTRACT: A placholder TextMap context propagator for OpenTelemetry

package OpenTelemetry::Context::Propagation::TextMap::Noop;

our $VERSION = '0.001';

class OpenTelemetry::Context::Propagation::TextMap::Noop {
    use OpenTelemetry::Context;
    use OpenTelemetry::Context::Propagation::TextMap;

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Context::Propagation::TextMap::SETTER
    ) {
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Context::Propagation::TextMap::GETTER
    ) {
        return $context;
    }

    method keys () { }
}
