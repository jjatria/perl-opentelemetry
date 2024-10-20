use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An event in an OpenTelemetry span

package OpenTelemetry::Trace::Event;

our $VERSION = '0.026';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::Event :does(OpenTelemetry::Attributes) {
    use Time::HiRes;

    field $name      :param :reader   = undef;
    field $timestamp :param :reader //= Time::HiRes::time;

    ADJUST {
        $name //= do {
            $logger->warn("Missing name when creating a span event. Setting to 'empty'");
            'empty';
        };
    }
}
