package OpenTelemetry::Constants;

our $VERSION = '0.032';

use Scalar::Util ();

use constant {
    SPAN_STATUS_UNSET     => 0,
    SPAN_STATUS_OK        => 1,
    SPAN_STATUS_ERROR     => 2,

    SPAN_KIND_INTERNAL    => 1,
    SPAN_KIND_SERVER      => 2,
    SPAN_KIND_CLIENT      => 3,
    SPAN_KIND_PRODUCER    => 4,
    SPAN_KIND_CONSUMER    => 5,

    # TODO: the dualvar is nice in theory, but it might be a little
    # too clever. It does mean we need to jump through some hoops
    # when exporting. But if we don't keep this mapping here, then
    # where? More constants? A utility function, like in
    # Log::Any::Util? And if so, where? OpenTelemetry::Common?
    # OpenTelemetry::Logs::Logger?
    LOG_LEVEL_TRACE       => Scalar::Util::dualvar(  1, 'TRACE'  ),
    LOG_LEVEL_TRACE2      => Scalar::Util::dualvar(  2, 'TRACE2' ),
    LOG_LEVEL_TRACE3      => Scalar::Util::dualvar(  3, 'TRACE3' ),
    LOG_LEVEL_TRACE4      => Scalar::Util::dualvar(  4, 'TRACE4' ),
    LOG_LEVEL_DEBUG       => Scalar::Util::dualvar(  5, 'DEBUG'  ),
    LOG_LEVEL_DEBUG2      => Scalar::Util::dualvar(  6, 'DEBUG2' ),
    LOG_LEVEL_DEBUG3      => Scalar::Util::dualvar(  7, 'DEBUG3' ),
    LOG_LEVEL_DEBUG4      => Scalar::Util::dualvar(  8, 'DEBUG4' ),
    LOG_LEVEL_INFO        => Scalar::Util::dualvar(  9, 'INFO'   ),
    LOG_LEVEL_INFO2       => Scalar::Util::dualvar( 10, 'INFO2'  ),
    LOG_LEVEL_INFO3       => Scalar::Util::dualvar( 11, 'INFO3'  ),
    LOG_LEVEL_INFO4       => Scalar::Util::dualvar( 12, 'INFO4'  ),
    LOG_LEVEL_WARN        => Scalar::Util::dualvar( 13, 'WARN'   ),
    LOG_LEVEL_WARN2       => Scalar::Util::dualvar( 14, 'WARN2'  ),
    LOG_LEVEL_WARN3       => Scalar::Util::dualvar( 15, 'WARN3'  ),
    LOG_LEVEL_WARN4       => Scalar::Util::dualvar( 16, 'WARN4'  ),
    LOG_LEVEL_ERROR       => Scalar::Util::dualvar( 17, 'ERROR'  ),
    LOG_LEVEL_ERROR2      => Scalar::Util::dualvar( 18, 'ERROR2' ),
    LOG_LEVEL_ERROR3      => Scalar::Util::dualvar( 19, 'ERROR3' ),
    LOG_LEVEL_ERROR4      => Scalar::Util::dualvar( 20, 'ERROR4' ),
    LOG_LEVEL_FATAL       => Scalar::Util::dualvar( 21, 'FATAL'  ),
    LOG_LEVEL_FATAL2      => Scalar::Util::dualvar( 22, 'FATAL2' ),
    LOG_LEVEL_FATAL3      => Scalar::Util::dualvar( 23, 'FATAL3' ),
    LOG_LEVEL_FATAL4      => Scalar::Util::dualvar( 24, 'FATAL4' ),

    # TODO: Since these are now used for exporting both logs and
    # traces, we cannot really give them the TRACE_ prefix. This
    # name is arguably better, but it might be unfamiliar to
    # non-Perl OpenTelemetry users.
    EXPORT_RESULT_SUCCESS => 0,
    EXPORT_RESULT_FAILURE => 1,
    EXPORT_RESULT_TIMEOUT => 2,

    INVALID_TRACE_ID      => "\0" x 16,
    INVALID_SPAN_ID       => "\0" x  8,
};

use constant {
    # TODO: Redefining these here for now so we don't break the
    # code that still uses them. I think we can still break things
    # but we should decide on a stability policy and come up with
    # some deprecation strategy for the future.
    TRACE_EXPORT_SUCCESS  => EXPORT_RESULT_SUCCESS,
    TRACE_EXPORT_FAILURE  => EXPORT_RESULT_FAILURE,
    TRACE_EXPORT_TIMEOUT  => EXPORT_RESULT_TIMEOUT,

    HEX_INVALID_TRACE_ID  => unpack('H*', INVALID_TRACE_ID),
    HEX_INVALID_SPAN_ID   => unpack('H*', INVALID_SPAN_ID),
};

our %EXPORT_TAGS = (
    log => [qw(
        LOG_LEVEL_TRACE
        LOG_LEVEL_TRACE2
        LOG_LEVEL_TRACE3
        LOG_LEVEL_TRACE4
        LOG_LEVEL_DEBUG
        LOG_LEVEL_DEBUG2
        LOG_LEVEL_DEBUG3
        LOG_LEVEL_DEBUG4
        LOG_LEVEL_INFO
        LOG_LEVEL_INFO2
        LOG_LEVEL_INFO3
        LOG_LEVEL_INFO4
        LOG_LEVEL_WARN
        LOG_LEVEL_WARN2
        LOG_LEVEL_WARN3
        LOG_LEVEL_WARN4
        LOG_LEVEL_ERROR
        LOG_LEVEL_ERROR2
        LOG_LEVEL_ERROR3
        LOG_LEVEL_ERROR4
        LOG_LEVEL_FATAL
        LOG_LEVEL_FATAL2
        LOG_LEVEL_FATAL3
        LOG_LEVEL_FATAL4
    )],
    span_kind => [qw(
        SPAN_KIND_INTERNAL
        SPAN_KIND_SERVER
        SPAN_KIND_CLIENT
        SPAN_KIND_PRODUCER
        SPAN_KIND_CONSUMER
    )],
    span_status => [qw(
        SPAN_STATUS_UNSET
        SPAN_STATUS_OK
        SPAN_STATUS_ERROR
    )],
    trace_export => [qw(
        TRACE_EXPORT_SUCCESS
        TRACE_EXPORT_FAILURE
        TRACE_EXPORT_TIMEOUT
    )],
    export => [qw(
        EXPORT_RESULT_SUCCESS
        EXPORT_RESULT_FAILURE
        EXPORT_RESULT_TIMEOUT
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

our @EXPORT_OK = map @$_, @EXPORT_TAGS{qw( export trace span log )};

1;
