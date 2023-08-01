use Object::Pad;
# ABSTRACT: A composite context propagator for OpenTelemetry

package OpenTelemetry::Propagator::Composite;

our $VERSION = '0.001';

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

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Propagator::Composite - A composite context propagator for OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry::Propagator::Composite;
    use OpenTelemetry::Propagator::Baggage;
    use OpenTelemetry::Propagator::TraceContext;

    my $propagator = OpenTelemetry::Propagator::Composite->new(
        OpenTelemetry::Propagator::Baggage->new,
        OpenTelemetry::Propagator::TraceContext->new,
    );

    # Inject data from the context to a carrier using all injectors in order
    my $carrier = {};
    $propagator->inject( $carrier, $context );

    # Extract data from a carrier to the context using all extractors in order
    my $new_context = $propagator->extract( $carrier, $context );

=head1 DESCRIPTION

This package defines a propagator class that interact with the context
(which can be either an implicit or explicit instance of
L<OpenTelemetry::Context>) and inject or extract data using a composite of
objects implementing the L<OpenTelemetry::Propagator> interface. Injectors
and extractors can be set separately, and will be called in order when they
are used.

This composite propagator itself implements the L<OpenTelemetry::Propagator>
interface.

=head1 METHODS

=head2 new

    $propagator = OpenTelemetry::Propagator::Composite->new(@propagators)

Constructs a new instance of this propagator. Takes a potentially empty list
of objects that implement the L<OpenTelemetry::Propagator> interface. Calls
to C<inject> and C<extract> will be delegated to these in the order they were
specified.

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Context>

=item L<OpenTelemetry::Propagator>

=back

=head1 COPYRIGHT AND LICENSE

...
