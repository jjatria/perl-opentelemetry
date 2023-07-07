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

    method all () { %data }

    method get ( $name ) { $data{$name} }

    method delete ( $name ) {
        delete $data{$name};
        return;
    };

    method set ( $name, $value, $meta ) {
        $data{$name} = OpenTelemetry::Baggage::Entry->new(
            value => $value,
            meta  => $meta,
        );
        return;
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
    my %new = %{ from_context $context };
    return $context unless exists $new{$name};

    delete $new{$name};
    $context->set( $BAGGAGE_KEY => \%new );
}

sub builder ( $ ) {
    OpenTelemetry::Baggage::Builder->new;
}

1;
