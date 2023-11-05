use Object::Pad;
# ABSTRACT: Propagate context using the W3C Baggage format

package OpenTelemetry::Propagator::Baggage;

our $VERSION = '0.013';

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
