use Object::Pad;
# ABSTRACT: An event in an OpenTelemetry span

package OpenTelemetry::Trace::Event;

our $VERSION = '0.001';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::Event {
    use Time::HiRes;

    has $name        :param :reader = undef;
    has $timestamp   :param :reader = undef;
    has $attributes  :param :reader = undef;

    ADJUST {
        $name //= do {
            $logger->warn("Missing name when creating a span event. Setting to 'empty'");
            'empty';
        };

        $attributes //= {};
        $timestamp  //= Time::HiRes::time;
    }
}
