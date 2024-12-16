use Object::Pad;
# ABSTRACT: A log factory for OpenTelemetry

package OpenTelemetry::Logs::Logger;

our $VERSION = '0.027';

# TODO: Should this implement an interface like that of Mojo::Log
# or Log::Any? It would mean that writing adapters like
# Log::Any::Adapter::OpenTelemetry for other loggers (eg. Log::ger,
# Dancer2::Logger) would be simpler, since the high-level logging
# interface would already exist. I don't think this goes against
# the standard.
class OpenTelemetry::Logs::Logger {
    method emit_record ( %args ) { }
}
