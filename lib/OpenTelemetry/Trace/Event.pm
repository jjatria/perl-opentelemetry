use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An event in an OpenTelemetry span

package OpenTelemetry::Trace::Event;

our $VERSION = '0.034';

class OpenTelemetry::Trace::Event :does(OpenTelemetry::Attributes) {
    use Time::HiRes;
    use OpenTelemetry::Common ();

    my $logger = OpenTelemetry::Common::internal_logger;

    field $name      :param :reader   = undef;
    field $timestamp :param :reader //= Time::HiRes::time;

    ADJUST {
        $name //= do {
            $logger->warn("Missing name when creating a span event. Setting to 'empty'");
            'empty';
        };
    }
}
