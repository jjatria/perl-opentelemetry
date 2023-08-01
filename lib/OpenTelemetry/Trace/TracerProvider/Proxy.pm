use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A placeholder TracerProvider that delegates to a real one

package OpenTelemetry::Trace::TracerProvider::Proxy;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::TracerProvider::Proxy :isa(OpenTelemetry::Trace::TracerProvider) {
    use OpenTelemetry::Trace::Tracer::Proxy;

    use Future;
    use Mutex;

    field $delegate;
    field %registry;

    field $delegate_lock = Mutex->new;
    field $registry_lock = Mutex->new;

    method delegate ($new) {
        if ( $delegate ) {
            $logger->warn('Attempt to reset delegate in TracerProvider proxy ignored');
            return $self;
        }

        $delegate_lock->enter( sub {
            $delegate = $new;

            for my $name ( keys %registry ) {
                my ( $proxy, %args ) = @{ delete $registry{$name} };
                $proxy->delegate( $delegate->tracer( %args ) );
            }
        });

        return $self;
    }

    method tracer ( %args ) {
        # TODO: Is this correct?
        my $name = $args{name} //= '';

        $registry_lock->enter( sub {
            return $delegate->tracer( %args ) if $delegate;

            $registry{$name} //= [ OpenTelemetry::Trace::Tracer::Proxy->new, %args ];

            $registry{$name}[0];
        });
    }
}
