#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Constants';

is \%OpenTelemetry::Constants::EXPORT_TAGS, {
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
    span => [qw(
        INVALID_SPAN_ID
        HEX_INVALID_SPAN_ID
        SPAN_STATUS_UNSET
        SPAN_STATUS_OK
        SPAN_STATUS_ERROR
        SPAN_KIND_INTERNAL
        SPAN_KIND_SERVER
        SPAN_KIND_CLIENT
        SPAN_KIND_PRODUCER
        SPAN_KIND_CONSUMER
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
    trace => [qw(
        INVALID_TRACE_ID
        HEX_INVALID_TRACE_ID
        TRACE_EXPORT_SUCCESS
        TRACE_EXPORT_FAILURE
        TRACE_EXPORT_TIMEOUT
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
}, 'Export tags are correct';

is \@OpenTelemetry::Constants::EXPORT_OK, [qw(
        EXPORT_RESULT_SUCCESS
        EXPORT_RESULT_FAILURE
        EXPORT_RESULT_TIMEOUT
        INVALID_TRACE_ID
        HEX_INVALID_TRACE_ID
        TRACE_EXPORT_SUCCESS
        TRACE_EXPORT_FAILURE
        TRACE_EXPORT_TIMEOUT
        INVALID_SPAN_ID
        HEX_INVALID_SPAN_ID
        SPAN_STATUS_UNSET
        SPAN_STATUS_OK
        SPAN_STATUS_ERROR
        SPAN_KIND_INTERNAL
        SPAN_KIND_SERVER
        SPAN_KIND_CLIENT
        SPAN_KIND_PRODUCER
        SPAN_KIND_CONSUMER
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
)], 'Exportable functions are correct';

is \@OpenTelemetry::EXPORT, [], 'Exports nothing by default';

done_testing;
