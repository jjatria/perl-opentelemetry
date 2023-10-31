use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Represents TraceFlags in a W3C TraceContext

package OpenTelemetry::Propagator::TraceContext::TraceFlags;

our $VERSION = '0.011';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Propagator::TraceContext::TraceFlags {
    field $flags :param :reader = 0;

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
