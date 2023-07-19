package OpenTelemetry::X;

our $VERSION = '0.001';

use X::Tiny;
use parent 'X::Tiny::Base';

sub to_string { shift->[0] } # Do not print full stack trace

sub create {
    my $pkg = ref($_[0]) || $_[0];

    die "The use of $pkg->create is not allowed. Call OpenTelemetry::X->create instead"
        unless $pkg eq 'OpenTelemetry::X';

    goto \&X::Tiny::create;
}

1;

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::X - An exception factory for OpenTelemetry

=head1 SYNOPSIS

    use OpenTelemetry::X;

    die OpenTelemetry::X->create( $type => $message );

=head1 DESCRIPTION

Because of the nature of OpenTelemetry, the vast majority of its operations
will attempt to recover from unexpected circumstances that might otherwise
be considered errors: one would not want an application crashing because of
the monitoring framework it uses. In these cases, OpenTelemetry prefers to
log that these events took place, and carry on.

Some errors, however, are the result of incorrectly using the framework's
API, or are otherwise unrecoverable. This package is there to make it easier
to handle and identify these cases.

The created exceptions overload stringification, so they should be usable
in most contexts where regular errors are used elsewhere in Perl.

=head1 CLASS METHODS

=head2 create

    $exception = OpenTelemetry::X->create( $type => $message )

Takes a string identifying an exception class and a message, and returns an
instance of an exception object of that type, with that message. The type will
be used as a sub-namespace under 'OpenTelemetry::X' to generate the class of
the exception to be constructed.

Constructed exceptions will be subclasses of OpenTelemetry::X, but this method
should only be called from this package.

=head1 SEE ALSO

=over

=item L<OpenTelemetry::X::Invalid>

=item L<OpenTelemetry::X::Parsing>

=item L<OpenTelemetry::X::Unsupported>

=back

=head1 COPYRIGHT AND LICENSE

...
