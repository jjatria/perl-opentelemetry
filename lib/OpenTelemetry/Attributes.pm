use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A class encapsulating attribute validation for OpenTelemetry

package OpenTelemetry::Attributes;

our $VERSION = '0.031';

class OpenTelemetry::AttributeMap {
    use Log::Any;
    use OpenTelemetry::Common ();

    my $logger = OpenTelemetry::Common::internal_logger;

    use List::Util qw( any pairs );
    use Ref::Util qw( is_hashref is_arrayref );
    use Storable 'dclone';

    field $max_fields       :param  = undef;
    field $max_field_length :param  = undef;
    field $dropped_fields   :reader = 0;
    field $data                     = {};

    ADJUSTPARAMS ($params) {
        $self->set( %{ delete $params->{data} // {} } );
    }

    method $validate_attribute_value ( $value ) {
        # Attribute values cannot be undefined but logging this is noisy
        return unless defined $value;

        if ( is_arrayref $value ) {
            if ( any { ref } @$value ) {
                $logger->trace('Attribute values that are lists cannot themselves hold references');
                return;
            }

            # Make sure we do not store the same reference that was
            # passed as a value, since the list on the other side of
            # that reference can be modified without going through
            # our checks
            $value = $max_field_length ? [
                map {
                        defined ? substr( $_, 0, $max_field_length ) : $_
                } @$value
            ] : [ @$value ];
        }
        elsif ( ref $value ) {
            $logger->trace('Attribute values cannot be references');
            return;
        }
        elsif ( $max_field_length ) {
            $value = substr $value, 0, $max_field_length;
        }

        ( 1, $value );
    }

    method set ( %args ) {
        my $recorded = 0;
        for ( pairs %args ) {
            my ( $key, $value ) = @$_;

            $key ||= do {
                $logger->debugf("Attribute names should not be empty. Setting to 'null' instead");
                'null';
            };

            my $fields = scalar %$data;
            $fields++ unless exists $data->{$key};

            next if $max_fields && $fields > $max_fields;

            my $ok;
            ( $ok, $value ) = $self->$validate_attribute_value($value);

            next unless $ok;

            $recorded++;
            $data->{$key} = $value;
        }

        my $dropped = +( keys %args ) - $recorded;

        $logger->debugf(
            'Dropped %s attribute entr%s because %s invalid%s',
            $dropped,
            $dropped > 1 ? ( 'ies', 'they were' ) : ( 'y', 'it was' ),
            $max_fields
                ? " or would have exceeded field limit ($max_fields)" : '',
        ) if $logger->is_debug && $dropped > 0;

        $dropped_fields += $dropped;

        return $self;
    }

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

    method dropped_attributes () { $attributes->dropped_fields }

    method attributes () { $attributes->to_hash }
}
