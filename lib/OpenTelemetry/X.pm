package OpenTelemetry::X;

our $VERSION = '0.026';

use X::Tiny;
use parent 'X::Tiny::Base';

sub to_string { '' . shift->[0] } # Do not print exception type

sub create {
    my $pkg = ref($_[0]) || $_[0];

    die "The use of $pkg->create is not allowed. Call OpenTelemetry::X->create instead"
        unless $pkg eq 'OpenTelemetry::X';

    goto \&X::Tiny::create;
}

1;
