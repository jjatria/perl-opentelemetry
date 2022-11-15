use Object::Pad;
# ABSTRACT: A placholder TextMap context propagator for OpenTelemetry

use experimental 'signatures';

package OpenTelemetry::Context::Propagation::TextMap;

our $VERSION = '0.001';

use constant {
    SETTER => sub ( $carrier, $key, $value ) { $carrier->{$key} = $value },
    GETTER => sub ( $carrier, $key         ) { $carrier->{$key}          },
};

class OpenTelemetry::Context::Propagation::TextMap {
    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = SETTER
    ) {
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = GETTER
    ) {
        return $context;
    }

    method keys () { }
}
