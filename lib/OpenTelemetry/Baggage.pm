use Object::Pad;
# ABSTRACT: Records and propagates baggage in a distributed trace

use experimental qw( signatures lexical_subs );
use OpenTelemetry::Context;

my $BAGGAGE_KEY = OpenTelemetry::Context->key('baggage');

package
    OpenTelemetry::Baggage::Entry;

our $VERSION = '0.001';

class OpenTelemetry::Baggage::Entry {
    has $value :param :reader;
    has $meta  :param :reader = {};
}

package
    OpenTelemetry::Baggage::Builder;

our $VERSION = '0.001';

class OpenTelemetry::Baggage::Builder {
    has %data;

    method set ( $name, $value, $meta = undef ) {
        $data{$name} = OpenTelemetry::Baggage::Entry->new(
            value => $value,
            meta  => $meta,
        );
        $self;
    }

    method build ( $context = undef ) {
        $context //= OpenTelemetry::Context->current;
        $context->set( $BAGGAGE_KEY => { %data } );
    }
}

package OpenTelemetry::Baggage;

our $VERSION = '0.001';

my sub from_context ( $context = undef ) {
    ( $context // OpenTelemetry::Context->current )->get($BAGGAGE_KEY) // {}
}

sub set ( $, $name, $value, $meta = undef, $context = undef ) {
    $context //= OpenTelemetry::Context->current;

    my %new = %{ from_context $context };
    $new{$name} = OpenTelemetry::Baggage::Entry->new( value => $value, meta => $meta );
    $context->set( $BAGGAGE_KEY => \%new );
}

sub get ( $, $name, $context = undef ) {
    from_context($context)->{$name}
}

sub all ( $, $context = undef ) {
    %{ from_context($context) }
}

sub delete ( $, $name, $context = undef ) {
    $context //= OpenTelemetry::Context->current;

    my %new = %{ from_context $context };
    return $context unless exists $new{$name};

    delete $new{$name};
    $context->set( $BAGGAGE_KEY => \%new );
}

sub clear ( $, $context = undef ) {
    $context //= OpenTelemetry::Context->current;
    $context->delete($BAGGAGE_KEY);
}

sub builder ( $ ) {
    OpenTelemetry::Baggage::Builder->new;
}

1;

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Baggage - Records and propagates baggage in a distributed trace

=head1 SYNOPSIS

    use OpenTelemetry::Baggage;

    # Set and get baggage in the context
    $context = OpenTelemetry::Baggage->set( $key => $value, $meta );
    $entry   = OpenTelemetry::Baggage->get( $key, $context );

    # Or if you are setting multiple entries
    my $builder = OpenTelemetry::Baggage->builder;
    $builder->set( $key => $value, $meta ); # As many times as you want
    $context = $builder->build;

=head1 DESCRIPTION

This package provides methods to read and store data using the
L<W3C Baggage Specification|https://w3c.github.io/baggage>, specifically for
use in the context of L<OpenTelemetry> data propagation.

=head2 Baggage Entries

Baggage values are stored (by L<set|/set>) and returned (by L<get|/get>) as
instances of an internal I<entry> object with the following two methods:

=over

=item value

Returns the value of the entry

=item meta

Returns the metadata associated to the entry, if any. If no metadata was set,
this method returns an undefined value

=back

=head1 CLASS METHODS

=head2 get

    $entry = OpenTelemetry::Baggage->get(
        $key,
        $context // OpenTelemetry::Context->current,
    )

Retrieve a value from the context. Takes a string to be used as the key,
and an optional L<OpenTelemetry::Context> object whence the key will be
fetched from. If no context is provided, the current context will be used.

If the key does not exist in the context, this method will return an
undefined value.

=head2 set

    $new_context = OpenTelemetry::Baggage->set(
        $key => $value,
        $meta    // undef,
        $context // OpenTelemetry::Context->current,
    )

Takes a key / value pair and stores it in the context as baggage. An optional
metadata string can be passed as a third parameter, in which case this will be
stored together with the pair.

An optional L<OpenTelemetry::Context> object can be passed as the fourth
argument, in which case the value will be stored in that context. If none is
provided, the current context will be used.

This method returns a new context object, which holds the new value.

=head2 delete

    $new_context = OpenTelemetry::Baggage->delete(
        $key,
        $context // OpenTelemetry::Context->current,
    )

Takes a string to be used as a key, and deletes the value stored under that
key from the baggage stored in the context.

An optional L<OpenTelemetry::Context> object can be passed as the second
argument, in which case the value will be deleted from that context. If none is
provided, the current context will be used.

This method returns a new context object, which will no longer have the
deleted key.

=head2 all

    %baggage = OpenTelemetry::Baggage->all(
        $context // OpenTelemetry::Context->current,
    )

Reads the baggage stored in the context and returns it as a list of
key / value pairs, where the values will be instances of the internal baggage
entry object (L<see above|/Baggage Entries>).

If an optional L<OpenTelemetry::Context> object is provided, the baggage will
be read from that context. Otherwise the current context will be used.

=head2 clear

    $new_context = OpenTelemetry::Baggage->clear(
        $context // OpenTelemetry::Context->current,
    )

Removes all baggage from the context and returns a new context with no baggage
in it.

If an optional L<OpenTelemetry::Context> object is provided, the baggage will
be read from that context. Otherwise the current context will be used.

=head2 builder

    $builder = OpenTelemetry::Baggage->builder;
    $builder->set( ... )->set( ... );
    $context = $builder->build;

This method facilitates setting multiple entries in the baggage of a context.
It returns an internal builder class that caches the entries internally and
writes them to the desired context only once when needed.

The builder implements two methods:

=over

=item set

    $builder = $builder->set( $key => $value, $meta );

Takes the same parameters as the L<set|/set> class method and returns the
builder itself.

=item build

    $new_context = $builder->build($context);

Takes an optional L<OpenTelemetry::Context> object and returns a new context
with all the keys in the provided context, and the baggage that has been
defined via calls to the builder's C<set> method.

If no context is provided, the current context will be used.

=back

=head1 COPYRIGHT AND LICENSE

...
