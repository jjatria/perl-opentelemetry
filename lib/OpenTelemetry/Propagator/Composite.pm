use Object::Pad;
# ABSTRACT: A composite context propagator for OpenTelemetry

package OpenTelemetry::Propagator::Composite;

our $VERSION = '0.013';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Propagator::Composite :does(OpenTelemetry::Propagator) {
    use List::Util qw( uniq first );
    use OpenTelemetry::Propagator::TextMap;
    use OpenTelemetry::X;

    field @injectors;
    field @extractors;

    sub BUILDARGS ( $, @args ) {
        my %return = (
            extractors => [ grep $_->can('extract'), @args ],
            injectors  => [ grep $_->can('inject'),  @args ],
        );

        $logger->warnf('No suitable propagators when constructing Composite propagator')
            if @args
            && ! @{ $return{extractors} // [] }
            && ! @{ $return{injectors}  // [] };

        %return;
    }

    ADJUSTPARAMS ($params) {
        @injectors  = @{ delete $params->{injectors}  // [] };
        @extractors = @{ delete $params->{extractors} // [] };
    }

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Propagator::TextMap::SETTER
    ) {
        $_->inject( $carrier, $context, $setter ) for @injectors;
        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Propagator::TextMap::GETTER
    ) {
        my $ctx = $context;
        $ctx = $_->extract( $carrier, $ctx, $getter ) for @extractors;
        return $ctx;
    }

    method keys () {
        uniq map $_->keys, @injectors, @extractors
    }
}
