use v5.26;
use Object::Pad;
# ABSTRACT: A context class for OpenTelemetry

package
    OpenTelemetry::Context::Key;

our $VERSION = '0.001';

class OpenTelemetry::Context::Key {
    use UUID::URandom 'create_uuid';

    has $name :param;
    has $salt;

    ADJUST { $salt = create_uuid };

    method string { $name . '-' . unpack( 'H*', $salt ) }
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
    my @stack;
    my $root = OpenTelemetry::Context->new;

    sub attach ( $, $context ) {
        push @stack, $context;
        return scalar @stack;
    }

    sub detach ( $, $token ) {
        my $matched = $token == @stack;

        # TODO: Exception handling?
        OpenTelemetry->handle_error(
            exception => 'calls to detach should match corresponding calls to attach',
        ) unless $matched;

        pop @stack;
        return $matched;
    }

    sub current ( $ ) {
        $stack[-1] // $root
    }
}

1;
