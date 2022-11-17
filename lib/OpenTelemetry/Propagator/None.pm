package OpenTelemetry::Propagator::None;

our $VERSION = '0.001';

use parent 'OpenTelemetry::Context::Propagation::TextMap::Noop';

1;
