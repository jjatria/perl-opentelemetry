use Object::Pad;
# ABSTRACT: A no-op implementation of a TracerProvider

package OpenTelemetry::Trace::TracerProvider;

our $VERSION = '0.001';

use Log::Any '$log';

class OpenTelemetry::Trace::TracerProvider {
    use OpenTelemetry::Trace::Tracer;

    has $tracer;

    method tracer ( %args ) {
        $log->warnf('Invalid tracer name on call to %s::tracer: got %s',
            __PACKAGE__,
            $args{name} // 'undef',
        ) unless $args{name};

        $tracer //= OpenTelemetry::Trace::Tracer->new;
    }
}
