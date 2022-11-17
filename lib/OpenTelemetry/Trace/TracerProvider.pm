use Object::Pad;
# ABSTRACT: A no-op implementation of a TracerProvider

package OpenTelemetry::Trace::TracerProvider;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::TracerProvider {
    use OpenTelemetry::Trace::Tracer;

    has $tracer;

    method tracer ( %args ) {
        $tracer //= OpenTelemetry::Trace::Tracer->new;
    }
}
