use Object::Pad;
# ABSTRACT: Represents TraceFlags in a W3C TraceContext

package OpenTelemetry::Propagator::TraceContext::TraceFlags;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Propagator::TraceContext::TraceFlags {
    has $flags :param :reader = 0;

    sub BUILDARGS ( $class, $flags = 0 ) {
        if ( $flags !~ /^\d+$/a ) {
            $logger->warnf('Non-numeric value when creating TraceFlags: %s', $flags);
            $flags = 0;
        }

        ( flags => $flags );
    }

    method to_string () { sprintf '%02x', $flags }

    method sampled () { !!( $flags & 1 ) }
}
