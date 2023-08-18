package
    Test2::Tools::OpenTelemetry;

use Exporter 'import';
our @EXPORT = qw( messages no_messages );

use Test2::API 'context';
use Test2::Compare qw( compare strict_convert );

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

1;
