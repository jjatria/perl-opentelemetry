package OpenTelemetry::Propagator::None;
# ABSTRACT: A context propagator for OpenTelemetry that does nothing

our $VERSION = '0.025';

use parent 'OpenTelemetry::Propagator::TextMap';

1;
