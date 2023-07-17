use Object::Pad;
# ABSTRACT: A placeholder TracerProvider that delegates to a real one

package OpenTelemetry::Trace::TracerProvider::Proxy;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::TracerProvider::Proxy :isa(OpenTelemetry::Trace::TracerProvider) {
    use mro;

    use OpenTelemetry::Trace::Tracer::Proxy;

    use Future;
    use Future::Mutex;
    use Future::AsyncAwait;

    has $delegate;
    has %registry;

    has $lock;
    has $registry_lock;

    ADJUST {
        $lock          = Future::Mutex->new;
        $registry_lock = Future::Mutex->new;
    }

    method delegate ($new) {
        if ( $delegate ) {
            $logger->warn('Attempt to reset delegate in TracerProvider proxy ignored');
            return $self;
        }

        $lock->enter(
            async sub {
                $delegate = $new;

                for my $name ( keys %registry ) {
                    my ( $proxy, %args ) = @{ delete $registry{$name} };
                    $proxy->delegate( $delegate->tracer( %args ) );
                }

                1;
            }
        )->get;

        return $self;
    }

    method tracer ( %args ) {
        # TODO: Is this correct?
        my $name = $args{name} //= '';

        $registry_lock->enter(
            async sub {
                return $delegate->tracer( %args ) if $delegate;

                $registry{$name} //= [ OpenTelemetry::Trace::Tracer::Proxy->new, %args ];

                $registry{$name}[0];
            }
        )->get;
    }
}
