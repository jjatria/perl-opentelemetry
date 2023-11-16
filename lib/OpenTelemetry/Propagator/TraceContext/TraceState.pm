use Object::Pad;
# ABSTRACT: Represents the TraceState in a W3C TraceContext

package OpenTelemetry::Propagator::TraceContext::TraceState;

our $VERSION = '0.017';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Propagator::TraceContext::TraceState {
    use List::Util;

    my $MAX_MEMBERS = 32 * 2; # The member list is a flat list of pairs
    my $VALID_KEY = qr/
        ^
        (?:
                [ a-z ]     [ a-z 0-9 _ * \/ - ]{0,255} # simple-key
            | (?:                                       # multi-tenant-key
                [ a-z 0-9 ] [ a-z 0-9 _ * \/ - ]{0,240} #   tenant-id
                @
                [ a-z ]     [ a-z 0-9 _ * \/ - ]{0,13}  #   system-id
              )
        )
        $
    /xx;

    my $VALID_VALUE = qr/
        ^
            [ \x{20} \x{21}-\x{2B} \x{2D}-\x{3C} \x{3E}-\x{7E} ]{0,255}
            [        \x{21}-\x{2B} \x{2D}-\x{3C} \x{3E}-\x{7E} ]
        $
    /xx;

    field @members;

    # Private methods

    method $init ( @new ) {
        @members = splice @new, 0, $MAX_MEMBERS;
        $self
    }

    # Internal setting method: assumes parameters are validated
    # Having this in a separate method means we can call it from an
    # instance other than $self (eg. the one returned by the call to
    # 'delete' in the public 'set' method)
    method $set ( $key, $value ) {
        unshift @members, $key => $value;
        @members = splice @members, 0, $MAX_MEMBERS if @members > $MAX_MEMBERS;
        $self;
    }

    # Public interface

    sub from_string ( $class, $string = undef ) {
        $logger->debug('Got an undefined value instead of a string when parsing TraceState')
            unless defined $string;

        my @members;
        for ( grep $_, split ',', $string // '' ) {
            my ( $key, $value ) = split '=', s/^\s+|\s+$//gr, 2;

            next unless $key =~ $VALID_KEY && $value =~ $VALID_VALUE;
            push @members, $key => $value;
        }

        $class->new->$init(@members);
    }

    method to_string () {
        join ',', List::Util::pairmap { join '=', $a, $b } @members
    }

    # Gets the value
    method get ( $key ) {
        my ( undef, $value ) = List::Util::pairfirst { $a eq $key } @members;
        $value;
    }

    # Sets a new pair, overwriting any existing one with the same key
    method set ( $key, $value ) {
        if ( $key !~ $VALID_KEY ) {
            $logger->debugf("Invalid TraceState member key: '%s' => '%s'", $key, $value );
            return $self;
        }
        elsif ( $value !~ $VALID_VALUE ) {
            $logger->debugf("Invalid TraceState member value: '%s' => '%s'", $key, $value );
            return $self;
        }

        $self->delete($key)->$set( $key => $value );
    }

    # Returns a clone of the TraceState without the deleted key
    method delete ( $key ) {
        ( ref $self )->new->$init(
            List::Util::pairgrep { $a ne $key } @members
        );
    }
}
