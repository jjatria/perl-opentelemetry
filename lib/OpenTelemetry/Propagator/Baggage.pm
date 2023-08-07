use Object::Pad;
# ABSTRACT: Propagate context using the W3C Baggage format

package OpenTelemetry::Propagator::Baggage;

our $VERSION = '0.001';

class OpenTelemetry::Propagator::Baggage :does(OpenTelemetry::Propagator) {
    use OpenTelemetry::Baggage;
    use OpenTelemetry::Context;
    use OpenTelemetry::Propagator::TextMap;
    use URL::Encode qw( url_decode_utf8 url_encode_utf8 );

    my $KEY              = 'baggage';
    my $MAX_ENTRIES      = 180;
    my $MAX_ENTRY_LENGTH = 4096;
    my $MAX_TOTAL_LENGTH = 8192;

    method $encode (%baggage) {
        my $encoded = '';
        my $total = 0;

        for my $key ( keys %baggage ) {
            last if $total > $MAX_ENTRIES;

            next unless $baggage{$key};
            my $entry = join '=',
                url_encode_utf8($key),
                url_encode_utf8( $baggage{$key}->value );

            my $length = length $entry;
            next unless $length                    < $MAX_ENTRY_LENGTH
                     && $length + length($encoded) < $MAX_TOTAL_LENGTH;

            $encoded .= ',' if $encoded;
            $encoded .= $entry;

            if ( my $meta = $baggage{$key}->meta ) {
                $encoded .= ";$meta";
            }

            $total++;
        }

        $encoded;
    }

    method inject (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $setter  = OpenTelemetry::Propagator::TextMap::SETTER
    ) {
        my %baggage = OpenTelemetry::Baggage->all($context);
        return $self unless %baggage;

        my $encoded = $self->$encode(%baggage);
        $setter->( $carrier, $KEY, $encoded ) if $encoded;

        return $self;
    }

    method extract (
        $carrier,
        $context = OpenTelemetry::Context->current,
        $getter  = OpenTelemetry::Propagator::TextMap::GETTER
    ) {
        my $header = $carrier->$getter($KEY) or return $context;

        my $builder = OpenTelemetry::Baggage->builder;

        for ( split ',', $header =~ s/\s//gr ) {
            my ( $kv, $meta ) = split ';', $_, 2;
            my ( $key, $value ) = map url_decode_utf8($_), split '=', $kv, 2;
            $builder->set( $key, $value, $meta );
        }

        $builder->build($context);
    }

    method keys () { $KEY }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Propagator::Baggage - Propagate context using the W3C Baggage format

=head1 SYNOPSIS

    use OpenTelemetry::Baggage;
    use OpenTelemetry::Propagator::Baggage;

    my $propagator = OpenTelemetry::Propagator::Baggage;

    # Inject baggage data from the context to a carrier
    my $carrier = {};
    $propagator->inject( $carrier, $context );

    # Extract baggage data from a carrier to the context
    my $new_context = $propagator->extract( $carrier, $context );

    # The baggage data will be in the context
    my $baggage = OpenTelemetry::Baggage->all($new_context);

=head1 DESCRIPTION

This package defines a propagator class that can interact with the context
(which can be either an implicit or explicit instance of
L<OpenTelemetry::Context>) and inject or extract data using the
L<W3C Baggage format|https://w3c.github.io/baggage>.

It implements the propagator interface defined in
L<OpenTelemetry::Propagator>.

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Baggage>

=item L<OpenTelemetry::Context>

=item L<OpenTelemetry::Propagator>

=item L<W3C Baggage format|https://w3c.github.io/baggage/>

=back

=head1 COPYRIGHT AND LICENSE

...
