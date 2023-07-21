use Object::Pad;
# ABSTRACT: A composite context propagator for OpenTelemetry

package OpenTelemetry::Context::Propagation::Composite;

our $VERSION = '0.001';

class OpenTelemetry::Context::Propagation::Composite :does(OpenTelemetry::Propagator) {
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

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Context::Propagation::Composite - A composite context propagator for OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry::Context::Propagation::Composite;
    use OpenTelemetry::Propagator::Baggage;
    use OpenTelemetry::Propagator::TraceContext;

    my $propagator = OpenTelemetry::Context::Propagation::Composite->new(
        injectors => [
            OpenTelemetry::Propagator::Baggage->new,
            OpenTelemetry::Propagator::TraceContext->new,
        ],
        extractors => [
            OpenTelemetry::Propagator::TraceContext->new,
            OpenTelemetry::Propagator::Baggage->new,
        ],
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

    $propagator = OpenTelemetry::Context::Propagation::Composite->new(
        injectors  => \@injectors,
        extractors => \@extractors,
    )

Constructs a new instance of this propagator. Supported parameters to the
constructor are:

=over

=item injectors

Takes a reference to a potentially empty array with objects implementing the
L<OpenTelemetry::Propagator> interface. When calling C<inject>, the call will
be delegated to each of these in the order they were specified.

=item extractors

Takes a reference to a potentially empty array with objects implementing the
L<OpenTelemetry::Propagator> interface. When calling C<extrat>, the call will
be delegated to each of these in the order they were specified.

=back

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Context>

=item L<OpenTelemetry::Propagator>

=back

=head1 COPYRIGHT AND LICENSE

...
