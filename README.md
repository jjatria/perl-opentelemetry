# OpenTelemetry for Perl

This is part of an ongoing attempt at implementing the OpenTelemetry
standard in Perl. The distribution in this repository implements the
abstract OpenTelemetry API, with an SDK implementation being worked on
separately.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a
general-purpose API, SDK, and related tools required for the instrumentation
of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector
services to capture distributed traces and metrics from your application. You
can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this distribution fit in?

This distribution defines the core OpenTelemetry interfaces in the form of
abstract classes and no-op implementations. That is, it defines interfaces and
data types sufficient for a library or application to code against to produce
telemetry data, but does not actually collect, analyze, or export the data.

To collect and analyze telemetry data, *applications* should also install a
concrete implementation of the API. None exists at the moment, but work on
this should start next.

This separation allows *libraries* that produce telemetry data to depend only
on the API, deferring the choice of concrete implementation to the application
developer.

## How do I get started?

Install this distribution from the repository (the aim is for it to be on CPAN
at some point):

```
cd path/to/this/repo
cpanm install .
```

Then, use the OpenTelemetry interfaces to produces traces and other telemetry
data. Following is a basic example (although bear in mind this interface is
still being drafted, so some details might change):

``` perl
use OpenTelemetry;
use v5.36;

# Obtain the current default tracer provider
my $provider = OpenTelemetry->tracer_provider;

# Create a trace
my $tracer = $provider->tracer( name => 'my_app', version => '1.0' );

# Record spans
$tracer->in_span( outer => sub ( $span, $context ) {
    # In outer span

    $tracer->in_span( inner => sub ( $span, $context ) {
        # In inner span
    });
});
```
