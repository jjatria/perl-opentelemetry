package OpenTelemetry::Constants;

our $VERSION = '0.024';

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

$EXPORT_TAGS{span}  = [
    qw(
        INVALID_SPAN_ID
        HEX_INVALID_SPAN_ID
    ),
    map @$_, @EXPORT_TAGS{qw( span_status span_kind )},
];

$EXPORT_TAGS{trace} = [
    qw(
        INVALID_TRACE_ID
        HEX_INVALID_TRACE_ID
    ),
    @{ $EXPORT_TAGS{trace_export} },
];

use Exporter::Shiny;

our @EXPORT_OK = map @$_, @EXPORT_TAGS{qw( trace span )};

1;
