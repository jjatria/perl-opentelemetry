use Object::Pad;
# ABSTRACT: A context propagator for OpenTelemetry using string key / value pairs

use experimental 'signatures';

package OpenTelemetry::Propagator::TextMap;

our $VERSION = '0.029';

sub SETTER {
    sub ( $carrier, $key, $value ) { $carrier->{$key} = $value; return }
}

sub GETTER {
    sub ( $carrier, $key ) { $carrier->{$key} }
}

class OpenTelemetry::Propagator::TextMap :does(OpenTelemetry::Propagator) {
    use OpenTelemetry::Context;

    method inject (
        $carrier,
        $context = undef,
        $setter  = undef
    ) {
        return $self;
    }

    method extract (
        $carrier,
        $context = undef,
        $getter  = undef
    ) {
        return $context // OpenTelemetry::Context->current;
    }

    method keys () { }
}
