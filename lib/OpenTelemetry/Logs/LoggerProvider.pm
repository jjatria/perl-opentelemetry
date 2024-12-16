use Object::Pad;
# ABSTRACT: Provides access to OpenTelemetry Loggers

package OpenTelemetry::Logs::LoggerProvider;

our $VERSION = '0.027';

class OpenTelemetry::Logs::LoggerProvider {
    use OpenTelemetry::Logs::Logger;

    field $logger;

    method logger ( %args ) {
        $logger //= OpenTelemetry::Logs::Logger->new;
    }
}
