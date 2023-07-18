use Object::Pad;
# ABSTRACT: The status of an OpenTelemetry span

package
    OpenTelemetry::Trace::Span::Status;

our $VERSION = '0.001';

class OpenTelemetry::Trace::Span::Status {
    has $code        :param         = 'UNSET';
    has $description :param :reader = '';

    ADJUST {
        $code = 'UNSET' unless ( $code // '' ) =~ /^ (:? OK | ERROR ) $/x;
    }

    method ok    { $code eq 'OK'    }
    method error { $code eq 'ERROR' }
    method unset { $code eq 'UNSET' }
}
