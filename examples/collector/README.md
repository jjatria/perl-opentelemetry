# OpenTelemetry Collector Demo

This example defines a simple observability stack made up of an OpenTelemetry
Collector instance connected to a Jaeger and a Prometheus backend. Since this
will mostly be used for debugging purposes, the collector is also configured
to export any received telemetry to the console.

This example is based on the excellent demo available in the
[opentelemetry-collector-contrib] repository.

The example uses docker compose. In order to use it, make a local copy of this
repository and run the following command:

    docker compose up

You should then be able to see the following backends:

- Jaeger: http://localhost:16686
- Prometheus: http://localhost:9090

For a more full example that uses this stack please refer to the original
example, or to [OpenTelemetry::Guides::Exporter] which uses the Perl SDK.

[opentelemetry-collector-contrib]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/7e3d00326a919ccf053f90c0a61f057b5b0d450a/examples/demo
[opentelemetry::guides::exporter]: https://metacpan.org/pod/OpenTelemetry::Guides::Exporter
