use v5.26;
use Object::Pad;
# ABSTRACT: A context class for OpenTelemetry

package
    OpenTelemetry::Context::Key;

our $VERSION = '0.001';

class OpenTelemetry::Context::Key {
    use UUID::URandom 'create_uuid';

    has $name   :param;
    has $string :reader;

    ADJUST { $string = $name . '-' . unpack( 'H*', create_uuid ) };
}

package OpenTelemetry::Context;

our $VERSION = '0.001';

sub key ( $, $name ) {
    OpenTelemetry::Context::Key->new( name => $name );
}

class OpenTelemetry::Context {
    has $data :param = {};

    sub BUILDARGS ( $class, @args ) { ( data => { @args } ) }

    method get ( $key ) {
        $data->{ $key->string };
    }

    method set ( $key, $value ) {
        OpenTelemetry::Context->new( %$data, $key->string, $value )
    }
}

# Implicit context management
{
    use OpenTelemetry::Common;

    my @stack;
    my $root = OpenTelemetry::Context->new;

    sub attach ( $, $context ) {
        push @stack, $context;
        return scalar @stack;
    }

    sub detach ( $, $token ) {
        if ( $token eq @stack ) {
            pop @stack;
            return 1;
        }

        # TODO: Exception handling?
        OpenTelemetry::Common->error_handler->(
            exception => 'calls to detach should match corresponding calls to attach',
        );

        return 0;
    }

    sub current ( $ ) {
        $stack[-1] // $root
    }
}

1;
