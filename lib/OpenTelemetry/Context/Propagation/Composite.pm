use Object::Pad;
# ABSTRACT: A composite context propagator for OpenTelemetry

package OpenTelemetry::Context::Propagation::Composite;

our $VERSION = '0.001';

class OpenTelemetry::Context::Propagation::Composite {
    use List::Util qw( uniq first );
    use OpenTelemetry::Context::Propagation::TextMap;
    use OpenTelemetry::X;

    has @injectors;
    has @extractors;

    ADJUSTPARAMS ($params) {
        @injectors  = @{ delete $params->{injectors}  // [] };
        @extractors = @{ delete $params->{extractors} // [] };

        if ( my $bad = first { ! $_->can('inject') } @injectors ) {
            my $name = ref $bad || $bad;
            die OpenTelemetry::X->create(
                Invalid => "Injector for Composite propagator does not support an 'inject' method: $name",
            );

        }

        if ( my $bad = first { ! $_->can('extract') } @extractors ) {
            my $name = ref $bad || $bad;
            die OpenTelemetry::X->create(
                Invalid => "Extractor for Composite propagator does not support an 'extract' method: $name",
            );
        }
    }

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Context::Propagation::TextMap::SETTER
    ) {
        $_->inject( $carrier, $context, $setter ) for @injectors;
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Context::Propagation::TextMap::GETTER
    ) {
        my $ctx = $context;
        $ctx = $_->extract( $carrier, $ctx, $getter ) for @extractors;
        return $ctx;
    }

    method keys () {
        uniq map $_->keys, @injectors, @extractors
    }
}

