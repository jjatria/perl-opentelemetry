use Object::Pad;
# ABSTRACT: A context class for OpenTelemetry

use feature 'isa';

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
    use OpenTelemetry::X;

    has $data :param = {};

    sub BUILDARGS ( $class, %args ) { ( data => { %args } ) }

    method get ( $key ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless $key isa OpenTelemetry::Context::Key;

        $data->{ $key->string };
    }

    method set ( $key, $value ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless $key isa OpenTelemetry::Context::Key;

        OpenTelemetry::Context->new( %$data, $key->string, $value )
    }

    method delete ( $key ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless $key isa OpenTelemetry::Context::Key;

        my %copy = %$data;
        delete $copy{$key->string};

        OpenTelemetry::Context->new(%copy);
    }
}

# Implicit context management
{
    use OpenTelemetry::Common;

    my @stack;
    my $root = OpenTelemetry::Context->new;
    my $null = '~NULL~';

    sub attach ( $caller, $other = undef ) {
        # Allow both
        #     OpenTelemetry::Context->attach( $ctx )
        # and
        #     $ctx->attach;
        my $context = $caller isa OpenTelemetry::Context ? $caller : $other;

        if ( $context isa OpenTelemetry::Context ) {
            push @stack, $context;
            return scalar @stack;
        }

        OpenTelemetry::Common->error_handler->(
            exception => 'cannot attach without a context object',
        );

        return $null;
    }

    sub detach ( $, $token ) {
        return 0 if $token eq $null;

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

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Context - A context class for OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry::Context;

    my $key = OpenTelemetry::Context->key('something');
    my $ctx = OpenTelemetry::Context->current;

    # You can store and delete values in a context
    my $new = $ctx->set( $key => 'VALUE' );
    say $new->get($key); # Prints VALUE
    $new = $new->delete($key);
    say $new->get($key); # Warns because value is undefined

    # But the original context is immutable
    say defined $ctx->get($key) ? 1 : 0; # Prints 0

=head1 DESCRIPTION

This package provides an implementation of the OpenTelemetry
L<Context|https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/README.md>
class.

It contains methods to both construct new instances, and to store and retrieve
instances in a global context stack.

OpenTelemetry uses the context class for propagation of values within a
process across API boundaries. A key aspect of this context class is that it
is immutable, such that write operations always result in a new context being
created, which holds the values from the original context plus whatever new
values have been provided.

For more details, please refer to the OpenTelemetry specification.

=head2 Key objects

Values in a context are stored using a key object rather than a plain string.
See the L<key|/key> class method below for details on how to construct these
objets.

=head1 METHODS

=head2 new

    $context = OpenTelemetry::Context->new(%data)

Create a new context object. This method takes an optional set of key / value
pairs, which will be injected into the newly constructed context before
returning it.

=head2 get

    $value = $context->get($key)

Retrieve a value from the context. Takes an object representing a context key
(see the L<key> class method below) and returns the value stored in the
context object under that key. If no value is stored under that key, this
method will return an undefined value.

=head2 set

    $new_context = $context->set( $key => $value )

Takes a key object (see the L<key|/key> class method) and a value and returns
a new context object with all the values of the calling context, as well as
the provided value stored under the provided key.

=head2 delete

    $new_context = $context->delete($key)

Takes a key object (see the L<key|/key> class method) and returns a new
context object with all the values of the calling context, except the value
stored under the provided key.

=head1 CLASS METHODS

=head2 key

    $key = OpenTelemetry::Context->key($string)
    $key = $context->key($string)

Takes a string and creates a key object with that string as its name. The key
object can be used to store and retrieve values from a context object (see the
L<get|/get> and L<set|/set> methods above).

Two key objects with the same name are not interchangeable. They are unique to
ensure that multiple libraries that use the same context to store values under
the same name. See more details in
L<the OpenTelemetry specification|https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/README.md#create-a-key>.

=head2 current

    $context = OpenTelemetry::Context->current

Retrieve the current associated to the current execution unit. See below for
how to L<attach|/attach> and L<detach|/detach> contexts to modify the context
this method returns.

=head2 attach

    $token = OpenTelemetry::Context->attach($context)
    $token = $context->attach;

Associates a context to the current execution unit. This can be called either
as a method on an existing context (in which case the caller will be the one
attached) or as a class method with a context as its only argument (in which
case the provided context will be attached).

This method returns an opaque token that can be used to L<detach|/detach> this
associated at the end of the execution unit.

Calling this method with an invalid object will log an error and return a null
token which has no effect when used.

=head2 detach

    $bool = OpenTelemetry::Context->detach($token)
    $bool = $context->detach($token)

Takes a token, such as those returned by L<attach|/attach>, and resets the
context associated with the current execution unit to the value it had before
the corresponding call to L<attach|/attach> (the one that generated the
provided token).

Returns a true value if the operation was successful, or false otherwise.

The token will be used to try to map corresponding calls to attach and detach.
If a mismatch is detected, an error will be logged.

=head1 SEE ALSO

=over

=item L<OpenTelemetry specification on Context|https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/README.md>

=back

=head1 COPYRIGHT AND LICENSE

...
