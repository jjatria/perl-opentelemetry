use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A context class for OpenTelemetry

package
    OpenTelemetry::Context::Key;

our $VERSION = '0.028';

class OpenTelemetry::Context::Key {
    use UUID::URandom 'create_uuid';

    field $name   :param;
    field $string :reader;

    ADJUST { $string = $name . '-' . unpack( 'H*', create_uuid ) };
}

package OpenTelemetry::Context;

our $VERSION = '0.024';

sub key ( $, $name ) {
    OpenTelemetry::Context::Key->new( name => $name );
}

class OpenTelemetry::Context {
    use Carp qw( carp croak );
    use List::Util qw( pairs all );
    use OpenTelemetry::X;

    use isa 'OpenTelemetry::Context::Key';

    field $data;

    sub BUILDARGS ( $class, %args ) {
        carp 'The OpenTelemetry::Context constructor no longer takes arguments'
            if %args;
        return;
    }

    method $init ( %data ) {
        $data = \%data;
        $self;
    }

    method get ( $key ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless isa_OpenTelemetry_Context_Key $key;

        $data->{ $key->string };
    }

    method set ( @pairs ) {
        my %pairs;
        for ( pairs @pairs ) {
            croak OpenTelemetry::X->create(
                Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
            ) unless isa_OpenTelemetry_Context_Key $_->[0];

            $pairs{ $_->[0]->string } = $_->[1];
        }

        OpenTelemetry::Context->new->$init( %$data, %pairs );
    }

    method delete ( @keys ) {
        my @strings;
        for (@keys) {
            croak OpenTelemetry::X->create(
                Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
            ) unless isa_OpenTelemetry_Context_Key $_;

            push @strings, $_->string;
        }

        my %copy = %$data;
        delete @copy{@strings};

        OpenTelemetry::Context->new->$init(%copy);
    }
}

# Context management
{
    use Sentinel;

    use isa 'OpenTelemetry::Context';

    my $current = OpenTelemetry::Context->new;
    sub current :lvalue {
        sentinel(
            get => sub { $current },
            set => sub {
                die OpenTelemetry::X->create(
                    Invalid => 'Current context must be an instance of OpenTelemetry::Context, received instead ' . ref $_[0],
                ) unless isa_OpenTelemetry_Context $_[0];

                $current = $_[0];
            },
        );
    }
}

1;
