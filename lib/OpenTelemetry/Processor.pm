use Object::Pad;
# ABSTRACT: The abstract interface for OpenTelemetry processors

package OpenTelemetry::Processor;

our $VERSION = '0.015';

# NOTE: Moving this here creates a nice symmetry where we have
# OpenTelemetry::{Propagator,Processor,Exporter} at the top-level
# and allow for specific implementations to live under them.
# We should decide where we expect implementations that are
# specific to Traces / Logs / Metrics should live, though.
# For now, this ends up giving us
# * OpenTelemetry::Trace::Span::Processor
# * OpenTelemetry::Logs::LogRecord::Processor
# * OpenTelemetry::Metrics::Instrument::Processor (hypothetical)
# and the SDK implementations with `::SDK` in there somewhere.
role OpenTelemetry::Processor {
    method process;
    method shutdown;
    method force_flush;
}
