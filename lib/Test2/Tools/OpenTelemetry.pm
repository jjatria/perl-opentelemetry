package
    Test2::Tools::OpenTelemetry;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw(
    messages
    no_messages
    metrics
    no_metrics
);

use Feature::Compat::Defer;
use Test2::API 'context';
use Test2::Compare qw( compare strict_convert );

# TODO: Cannot lexically set a metrics adapter
use Metrics::Any::Adapter 'Test';

require Log::Any::Adapter;

my $capture_messages = sub {
    my $code = shift;

    Log::Any::Adapter->set(
        { lexically => \my $guard },
        Capture => to => \my @messages,
    );

    $code->();

    \@messages;
};

sub messages (&) { goto $capture_messages }

sub no_messages (&) {
    my $name = 'No messages logged';

    my $messages = shift->$capture_messages;
    my $context  = context;
    my $delta    = compare $messages, [], \&strict_convert;

    if ( $delta ) {
        $context->fail( $name, $delta->diag );
    }
    else {
        $context->ok( 1, $name );
    }

    $context->release;
    return !$delta;
}

my $capture_metrics = sub {
    my $code = shift;

    Metrics::Any::Adapter::Test->clear;
    defer { Metrics::Any::Adapter::Test->clear }

    $code->();

    [ split /\n/, Metrics::Any::Adapter::Test->metrics ];
};

sub metrics (&) { goto $capture_metrics }

sub no_metrics (&) {
    my $name = 'No metrics collected';

    my $data    = shift->$capture_metrics;
    my $context = context;
    my $delta   = compare $data, [], \&strict_convert;

    if ( $delta ) {
        $context->fail( $name, $delta->diag );
    }
    else {
        $context->ok( 1, $name );
    }

    $context->release;
    return !$delta;
}

1;
