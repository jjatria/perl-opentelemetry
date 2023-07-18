package
    OpenTelemetry::Test::Logs;

use strict;
use warnings;

use Log::Any::Adapter;

my ( $guard, @messages );
sub import {
    undef $guard;
    clear();

    Log::Any::Adapter->set(
        { lexically => \$guard },
        Capture => to => \@messages,
    );
}

sub messages { [ @messages ] }

sub clear { @messages = () }

1;
