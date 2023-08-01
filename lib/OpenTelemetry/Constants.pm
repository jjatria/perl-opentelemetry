package OpenTelemetry::Constants;

our $VERSION = '0.001';

use constant {
    SPAN_STATUS_UNSET    => 0,
    SPAN_STATUS_OK       => 1,
    SPAN_STATUS_ERROR    => 2,

    SPAN_KIND_INTERNAL   => 1,
    SPAN_KIND_SERVER     => 2,
    SPAN_KIND_CLIENT     => 3,
    SPAN_KIND_PRODUCER   => 4,
    SPAN_KIND_CONSUMER   => 5,

    TRACE_EXPORT_SUCCESS => 0,
    TRACE_EXPORT_FAILURE => 1,
    TRACE_EXPORT_TIMEOUT => 2,

    INVALID_TRACE_ID     => "\0" x 16,
    INVALID_SPAN_ID      => "\0" x  8,
};

use constant {
    HEX_INVALID_TRACE_ID => unpack('H*', INVALID_TRACE_ID),
    HEX_INVALID_SPAN_ID  => unpack('H*', INVALID_SPAN_ID),
};

our %EXPORT_TAGS = (
    span_status => [qw(
        SPAN_STATUS_UNSET
        SPAN_STATUS_OK
        SPAN_STATUS_ERROR
    )],
    span_kind => [qw(
        SPAN_KIND_INTERNAL
        SPAN_KIND_SERVER
        SPAN_KIND_CLIENT
        SPAN_KIND_PRODUCER
        SPAN_KIND_CONSUMER
    )],
    trace_export => [qw(
        TRACE_EXPORT_SUCCESS
        TRACE_EXPORT_FAILURE
        TRACE_EXPORT_TIMEOUT
    )],
);

use Exporter::Shiny;

our @EXPORT_OK = map @$_, values %EXPORT_TAGS, [qw(
    INVALID_TRACE_ID
    INVALID_SPAN_ID
    HEX_INVALID_TRACE_ID
    HEX_INVALID_SPAN_ID
)];

1;

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::Constatns - Constants used by OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry::Constants -span_status;
    use OpenTelemetry::Constants
        -trace_export => { -as => sub { shift =~ s/^TRACE_EXPORT_//r } };

=head1 DESCRIPTION

This package includes constants used by different parts of OpenTelemetry.

It uses L<Exporter::Tiny> to make it easier to export these symbols in a
way that is most helpful depending on the context. Please look at the
documentation of that module for details on what is supported.

=head1 CONSTANTS

=head2 Span status codes

These constants are used to specify the status of a span once it has
completed. They can be imported individually, or with the C<span_status> tag.

=over

=item SPAN_STATUS_UNSET

The status of a span when no status has been set. This is the default value.

=item SPAN_STATUS_OK

The status of a span that has been marked as having completed successfully by
an application.

=item SPAN_STATUS_ERROR

The status of a span that has been marked as not having completed successfully
by an application.

=back

=head2 Span kinds

These constants are used to specify the type of the span. They can be imported
individually, or with the C<span_kind> tag.

=over

=item SPAN_KIND_INTERNAL

The span is internal to an application, and is not at one of its boundaries
(eg. with other applications). If no kind is specified, this is the default
value.

=item SPAN_KIND_SERVER

The span covers the server-side handling of some remote network request.

=item SPAN_KIND_CLIENT

The span describes a request to a remote service.

=item SPAN_KIND_PRODUCER

The span describes a message sent to a broker. Unlike the client and server
kinds above, the action represented by this span ends once the broker accepts
the message, even if the logical processing of that message can take longer.

=item SPAN_KIND_CONSUMER

The span describes a consumer receiving a message from a broker.

=back

=head2 Trace export results

These constants are used to distinguish the result of a trace export
operation. They can be imported individually, or with the C<trace_export> tag.

=over

=item TRACE_EXPORT_SUCCESS

Marks an export operation as a success.

=item TRACE_EXPORT_FAILURE

Marks an export operation as a failure.

=item TRACE_EXPORT_TIMEOUT

Marks an export operation that was interrupted because it took too long.

=back

=head2 Placeholder invalid IDs

These constants are used as global null values for span and trace IDs.
They can be imported individually.

=over

=item INVALID_SPAN_ID

Returns a constant ID that can be used to identify an invalid span in bytes.

=item INVALID_TRACE_ID

Returns a constant ID that can be used to identify an invalid trace in bytes.

=item HEX_INVALID_SPAN_ID

Returns a constant ID that can be used to identify an invalid span as a
hexadecimal string in lowercase.

=item HEX_INVALID_TRACE_ID

Returns a constant ID that can be used to identify an invalid trace as a
hexadecimal string in lowercase.

=back

=head1 COPYRIGHT AND LICENSE

...
