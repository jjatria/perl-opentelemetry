use Object::Pad;
# ABSTRACT: A placholder TextMap context propagator for OpenTelemetry

package OpenTelemetry::Context::Propagation::TextMap::Noop;

our $VERSION = '0.001';

class OpenTelemetry::Context::Propagation::TextMap::Noop {
    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter = sub ( $carrier, $key, $value ) { $carrier->{$key} = $value }
    ) {
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter = sub ( $carrier, $key ) { $carrier->{$key} }
    ) {
        return $context;
    }

    method keys () { }
}
