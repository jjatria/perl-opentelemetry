package OpenTelemetry;
# ABSTRACT: A Perl implementation of the OpenTelemetry standard

use strict;
use warnings;
use experimental qw( isa signatures );

our $VERSION = '0.017';

use Mutex;
use OpenTelemetry::Common;
use OpenTelemetry::Context;
use OpenTelemetry::Propagator::None;
use OpenTelemetry::Trace::TracerProvider;
use OpenTelemetry::X;
use Scalar::Util 'refaddr';
use Ref::Util 'is_coderef';
use Sentinel;

use Log::Any;

use Exporter::Shiny qw(
    otel_config
    otel_context_with_span
    otel_current_context
    otel_error_handler
    otel_handle_error
    otel_logger
    otel_propagator
    otel_span_from_context
    otel_tracer_provider
    otel_untraced_context
);

my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );
sub logger { $logger }
sub _generate_otel_logger { \&logger }

{
    my $lock = Mutex->new;
    my $instance = OpenTelemetry::Trace::TracerProvider->new;

    my $set = sub ( $new ) {
        die OpenTelemetry::X->create(
            Invalid => 'Global tracer provider must be a subclass of OpenTelemetry::Trace::TracerProvider, got instead ' . ( ref $new || 'a plain scalar' ),
        ) unless $new isa OpenTelemetry::Trace::TracerProvider;

        $lock->enter( sub { $instance = $new });
    };

    sub _generate_otel_tracer_provider {
        my $x = sub :lvalue { sentinel get => sub { $instance }, set => $set };
    }

    sub tracer_provider :lvalue { sentinel get => sub { $instance }, set => $set }
}

{
    my $lock = Mutex->new;
    my $instance = OpenTelemetry::Propagator::None->new;

    my $set = sub ( $new ) {
        die OpenTelemetry::X->create(
            Invalid => 'Global propagator must implement the OpenTelemetry::Propagator role, got instead ' . ( ref $new || 'a plain scalar' ),
        ) unless $new && $new->DOES('OpenTelemetry::Propagator');

        $lock->enter( sub { $instance = $new });
    };

    sub _generate_otel_propagator {
        my $x = sub :lvalue { sentinel get => sub { $instance }, set => $set };
    }

    sub propagator :lvalue { sentinel get => sub { $instance }, set => $set }
}

sub _generate_otel_untraced_context {
    my $sub = sub :lvalue { OpenTelemetry::Trace->untraced_context };
}

sub _generate_otel_current_context {
    my $sub = sub :lvalue { OpenTelemetry::Context->current };
}

sub _generate_otel_context_with_span {
    sub { OpenTelemetry::Trace->context_with_span(@_) };
}

sub _generate_otel_span_from_context {
    sub { OpenTelemetry::Trace->span_from_context(@_) };
}

sub _generate_otel_config {
    \&OpenTelemetry::Common::config;
}

{
    my $lock = Mutex->new;
    my $instance = sub (%args) {
        my $error = join ' - ', grep defined,
            @args{qw( message exception )};

        $logger->error( "OpenTelemetry error: $error", $args{details} );
    };

    my $set = sub ( $new ) {
        die OpenTelemetry::X->create(
            Invalid => 'Global error handler must be a code reference, got instead ' . ( ref $new || 'a plain scalar' ),
        ) unless is_coderef $new;

        $lock->enter( sub { $instance = $new });
    };

    sub _generate_otel_error_handler {
        my $x = sub :lvalue { sentinel get => sub { $instance }, set => $set };
    }

    sub error_handler :lvalue { sentinel get => sub { $instance }, set => $set }

    sub _generate_otel_handle_error { sub {  $instance->(@_); return } }
    sub                handle_error { shift; $instance->(@_); return   }
}

1;
