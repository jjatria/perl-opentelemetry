#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Constants';

is \%OpenTelemetry::Constants::EXPORT_TAGS, {
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
}, 'Export tags are correct';

is \@OpenTelemetry::Constants::EXPORT_OK, [qw(
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
)], 'Exportable functions are correct';

is \@OpenTelemetry::EXPORT, [], 'Exports nothing by default';

done_testing;
