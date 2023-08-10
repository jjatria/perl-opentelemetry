use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A class encapsulating attribute validation for OpenTelemetry

package OpenTelemetry::Attributes;

our $VERSION = '0.001';

class OpenTelemetry::AttributeMap {
    use Log::Any;
    my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

    use List::Util qw( any pairs );
    use Ref::Util qw( is_hashref is_arrayref );
    use Storable 'dclone';

    field $max_fields       :param  = undef;
    field $max_field_length :param  = undef;
    field $recorded_fields  :reader = 0;
    field $data                     = {};

    ADJUSTPARAMS ($params) {
        $self->set( %{ delete $params->{data} // {} } );
    }

    method $validate_attribute_value ( $value ) {
        # Attribute values cannot be undefined but logging this is noisy
        return unless defined $value;

        if ( is_hashref $value ) {
            $logger->debugf('Attribute values cannot be hash references');
            return;
        }

        if ( is_arrayref $value ) {
            if ( any { ref || !defined } @$value ) {
                $logger->debugf('Attributes values that are lists cannot themselves hold references or undefined values');
                return;
            }

            if ( $max_field_length ) {
                $value = [ map substr( $_, 0, $max_field_length ), @$value ];
            }
        }
        elsif ( $max_field_length ) {
            $value = substr $value, 0, $max_field_length;
        }

        ( 1, $value );
    }

    method dropped_fields () {
        $recorded_fields - scalar %$data;
    }

    method set ( %args ) {
        my $dropped;

        for ( pairs %args ) {
            my ( $key, $value ) = @$_;

            $key ||= do {
                $logger->debugf("Attribute names should not be empty. Setting to 'null' instead");
                'null';
            };

            my $fields = scalar %$data;
            unless ( exists $data->{$key} ) {
                $fields++;
                $recorded_fields++;
            }

            if ( $max_fields && $fields > $max_fields ) {
                $dropped++;
                next;
            }

            my $ok;
            ( $ok, $value ) = $self->$validate_attribute_value($value);

            next unless $ok;

            $data->{$key} = $value;
        }

        $logger->debugf(
            "Dropped $dropped attribute entr%s because %s would exceed specified limit ($max_fields)",
            $dropped > 1 ? ( 'ies', 'they' ) : ( 'y', 'it' ),
        ) if $dropped;

        return $self;
    }

    method get ( $key ) { $data->{$key} }

    method to_hash () {
        dclone $data;
    }
}

role OpenTelemetry::Attributes {
    field $attributes;

    ADJUSTPARAMS ( $params ) {
        $attributes = OpenTelemetry::AttributeMap->new(
            data             => delete $params->{attributes} // {},
            max_fields       => delete $params->{attribute_count_limit},
            max_field_length => delete $params->{attribute_length_limit},
        );
    }

    method _set_attribute ( %new ) {
        $attributes->set(%new);
        $self;
    }

    method dropped_attributes () { $attributes->dropped_fields }

    method recorded_attributes () { $attributes->recorded_fields }

    method attributes () { $attributes->to_hash }
}
