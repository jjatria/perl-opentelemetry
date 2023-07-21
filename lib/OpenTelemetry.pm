package OpenTelemetry;
# ABSTRACT: A Perl implementation of the OpenTelemetry standard

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.001';

use OpenTelemetry::Common;
use OpenTelemetry::Propagator::None;
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
    return $propagation //= OpenTelemetry::Propagator::None->new;
}

sub logger { $logger }

sub error_handler { goto \&OpenTelemetry::Common::error_handler }

sub handle_error ( $pkg, %args ) { $pkg->error_handler->(%args); return }

1;
