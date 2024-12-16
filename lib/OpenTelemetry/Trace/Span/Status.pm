use Object::Pad ':experimental(init_expr)';
# ABSTRACT: The status of an OpenTelemetry span

package OpenTelemetry::Trace::Span::Status;

our $VERSION = '0.027';

use Log::Any;
my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

class OpenTelemetry::Trace::Span::Status {
    use OpenTelemetry::Constants
        -span_status => { -as => sub { shift =~ s/^SPAN_STATUS_//r } };

    field $code        :param :reader = UNSET;
    field $description :param :reader = undef;

    ADJUST {
        $code = UNSET if $code && $code < UNSET || $code > ERROR;

        if ( $code != ERROR && $description ) {
            undef $description;
            $logger->warn('Ignoring description on a non-error span status');
        }

        $description //= '';
    }

    sub ok    ( $class, %args ) { $class->new( %args, code => OK    ) }
    sub error ( $class, %args ) { $class->new( %args, code => ERROR ) }
    sub unset ( $class, %args ) { $class->new( %args, code => UNSET ) }

    method is_ok    () { $code == OK    }
    method is_error () { $code == ERROR }
    method is_unset () { $code == UNSET }
}
