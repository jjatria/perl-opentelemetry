package OpenTelemetry::X::Base;

our $VERSION = '0.001';

use parent 'X::Tiny::Base';

sub to_string { shift->[0] }

1;
