use Object::Pad;
# ABSTRACT: A placholder TextMap context propagator for OpenTelemetry

use experimental 'signatures';

package OpenTelemetry::Context::Propagation::TextMap;

our $VERSION = '0.001';

sub SETTER { sub ( $carrier, $key, $value ) { $carrier->{$key} = $value } }
sub GETTER { sub ( $carrier, $key         ) { $carrier->{$key}          } }

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Context::Propagation::TextMap {
    use experimental 'try';

    use OpenTelemetry::Context;
    use OpenTelemetry::X;

    has $injector  :param;
    has $extractor :param;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => 'Injector for TextMap propagation object does not support an "inject" method',
        ) unless $injector->can('inject');

        die OpenTelemetry::X->create(
            Invalid => 'Extractor for TextMap propagation object does not support an "extract" method',
        ) unless $extractor->can('extract');
    }

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = SETTER
    ) {
        try {
            $injector->inject( $carrier, $context, $setter );
        }
        catch ($e) {
            $logger->warnf("Unable to inject context to carrier: $e");
        }

        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = GETTER
    ) {
        try {
            $extractor->extract( $carrier, $context, $getter );
        }
        catch ($e) {
            $logger->warnf("Unable to extract context from carrier: $e");
        }

        return $context;
    }

    method keys () { $injector->keys }
}
