use Object::Pad ':experimental(init_expr)';
# ABSTRACT: The status of an OpenTelemetry span

package
    OpenTelemetry::Trace::Span::Status;

our $VERSION = '0.001';

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

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Trace::Span::Status - The status of an OpenTelemetry span

=head1 SYNOPSIS

    use OpenTelemetry::Trace::Span::Status;

    my $ok    = OpenTelemetry::Trace::Span::Status->ok;
    my $unset = OpenTelemetry::Trace::Span::Status->unset;
    my $error = OpenTelemetry::Trace::Span::Status->error(
        description => 'Something went boom',
    );

=head1 DESCRIPTION

This module provides a class thar represents the status of a
L<OpenTelemetry::Trace::Span>. The status is represented by an internal code,
and can be either Unset, which is the default value; Ok, to represent the
status of an operation that is deemed to have completed successfully; or
Error, to represent an operation that did not complete successfully. Error
statuses can have a description string attached to them, to further explain
the source of the error, but setting a description on a non-error status will
issue a warning and the set description will be ignored.

Although not mandatory, libraries marking the status of a span as "error"
are expected to provide a description of the reason, whicih should be publicly
documented.

=head1 METHODS

=head2 ok

    $status = OpenTelemetry::Trace::Span::Status->ok;

Creates a new status object with its code set to Ok. Any additional parameters
will be passed to the default constructor.

=head2 unset

    $status = OpenTelemetry::Trace::Span::Status->unset;

Creates a new status object with its code not set. Any additional parameters
will be passed to the default constructor.

=head2 error

    $status = OpenTelemetry::Trace::Span::Status->error(
        description => $description // '',
    );

Creates a new status object with its code set to Error. Any additional
parameters will be passed to the default constructor.

=head2 is_ok

    $bool = $status->is_ok;

Returns a true value if this instance represents an Ok status.

=head2 unset

    $bool = $status->is_unset;

Returns a true value if this instance represents an Unset status.

=head2 error

    $bool = $status->is_error;

Returns a true value if this instance represents an Error status.

=head1 COPYRIGHT AND LICENSE

...
