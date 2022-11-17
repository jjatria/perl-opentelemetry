package OpenTelemetry;
# ABSTRACT: A Perl implementation of the OpenTelemetry standard

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.001';

use OpenTelemetry::Context::Propagation::TextMap::Noop;
use OpenTelemetry::Trace::TracerProvider::Proxy;
use Log::Any '$logger';

my $tracer_provider;
sub tracer_provider ( $, $new = undef ) {
    # TODO: lock?
    $tracer_provider = $new if $new;
    return $tracer_provider //= OpenTelemetry::Trace::TracerProvider::Proxy->new;
}

my $propagation;
sub propagation ( $, $new = undef ) {
    $propagation = $new if $new;
    return $propagation //= OpenTelemetry::Context::Propagation::TextMap::Noop->new;
}

sub logger { $logger }

my $error_handler;
sub error_handler ( $, $handler = undef ) {
    $error_handler = $handler if $handler;
    return $error_handler //= sub (%args) {
        my $error = join ' - ', grep defined, @args{qw( exception message )};
        OpenTelemetry->logger->error("OpenTelemetry error: $error");
    };
}

sub handle_error ( $pkg, %args ) { $pkg->error_handler->(%args); return }

1;
