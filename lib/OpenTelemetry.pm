package OpenTelemetry;
# ABSTRACT: A Perl implementation of the OpenTelemetry standard

use strict;
use warnings;
use experimental qw( isa signatures );

our $VERSION = '0.001';

use OpenTelemetry::Common;
use OpenTelemetry::Propagator::None;
use OpenTelemetry::Trace::TracerProvider;

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

use Mutex;

{
    my $tracer_provider;
    my $lock = Mutex->new;
    sub tracer_provider ( $, $new = undef ) {
        $lock->enter( sub {
            $tracer_provider = $new if $new;
            return $tracer_provider //= OpenTelemetry::Trace::TracerProvider->new;
        });
    }
}

{
    my $propagation;
    my $lock = Mutex->new;
    sub propagation ( $, $new = undef ) {
        $lock->enter( sub {
            $propagation = $new if $new;
            return $propagation //= OpenTelemetry::Propagator::None->new;
        });
    }
}

sub logger { $logger }

sub error_handler { goto \&OpenTelemetry::Common::error_handler }

sub handle_error ( $pkg, %args ) { $pkg->error_handler->(%args); return }

1;
