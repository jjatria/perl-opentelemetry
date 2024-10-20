package
    Test2::Tools::OpenTelemetry;

our $VERSION = '0.026';

use Exporter 'import';
our @EXPORT = qw(
    messages no_messages
    metrics  no_metrics
);

use Feature::Compat::Defer;
use Test2::API 'context';
use Test2::Compare qw( compare strict_convert );

# TODO: Cannot lexically set a metrics adapter
use Metrics::Any::Adapter 'Test';

require Log::Any::Adapter;

my $messages = sub {
    my $code = shift;

    Log::Any::Adapter->set(
        { lexically => \my $guard },
        Capture => to => \my @messages,
    );

    $code->();

    \@messages;
};

my $metrics = sub {
    my $code = shift;

    Metrics::Any::Adapter::Test->clear;
    defer { Metrics::Any::Adapter::Test->clear }

    $code->();

    [ split /\n/, Metrics::Any::Adapter::Test->metrics ];
};

my $no = sub {
    my ( $code, $capture, $name ) = @_;

    my $context = context;
    my $data    = $code->$capture;
    my $delta   = compare $data, [], \&strict_convert;

    return $context->pass_and_release($name) unless $delta;
    $context->fail_and_release( $name, $delta->diag );
};

sub messages (&) { goto $messages }
sub metrics  (&) { goto $metrics  }

sub no_messages (&) { shift->$no( $messages, 'No messages logged'   ) }
sub no_metrics  (&) { shift->$no( $metrics,  'No metrics collected' ) }

1;
