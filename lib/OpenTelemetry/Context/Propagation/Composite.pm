use Object::Pad;
# ABSTRACT: A composite context propagator for OpenTelemetry

package OpenTelemetry::Context::Propagation::Composite;

our $VERSION = '0.001';

class OpenTelemetry::Context::Propagation::Composite {
    use List::Util 'uniq';

    has @injectors;
    has @extractors;

    sub BUILDARGS ( $, @args ) {
        return (
            extractors => [ grep $_->can('extract'), @args ],
            injectors  => [ grep $_->can('inject'),  @args ],
        )
    }

    ADJUST ($params) {
        @injectors  = @{ delete $params->{injectors}  // [] };
        @extractors = @{ delete $params->{extractors} // [] };
    }

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter = sub ( $carrier, $key, $value ) { $carrier->{$key} = $value }
    ) {
        $_->inject( $carrier, $context, $setter ) for @injectors;
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter = sub ( $carrier, $key ) { $carrier->{$key} }
    ) {
        my $ctx = $context;
        $ctx = $_->extract( $carrier, $ctx, $getter ) for @extractors;
        return $ctx;
    }

    method fields () {
        uniq map $_->fields, @injectors, @extractors
    }
}

