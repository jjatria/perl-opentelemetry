package OpenTelemetry::Integration::HTTP::Tiny;
# ABSTRACT: OpenTelemetry integration for HTTP::Tiny

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use Class::Method::Modifiers 'install_modifier';
use OpenTelemetry;
use OpenTelemetry::Constants qw( SPAN_STATUS_ERROR SPAN_KIND_CLIENT );

use parent 'OpenTelemetry::Integration';

my $loaded;
sub load ( $class, $load_deps = 0 ) {
    return if $loaded;
    return unless $load_deps or 'HTTP::Tiny'->can('new');

    require HTTP::Tiny;
    require URI;

    install_modifier 'HTTP::Tiny' => around => request => sub {
        my ( $code, $self, $method, $url, $options ) = @_;
        my $uri = URI->new("$url");
        my $path = $uri->path || '/';

        # TODO: A high-level DSL? Links?
        my $tracer = OpenTelemetry->tracer_provider->tracer( name => __PACKAGE__ );

        my $span = $tracer->create_span(
            name       => $path,,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                'http.method' => $method,
                'http.url'    => "$url",
                'http.user_agent' => $self->agent,
                'http.flavor' => '1.1', # HTTP::Tiny always uses HTTP/1.1

                # TODO: Should this be using ->host_port?
                # As per https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/http.md#http-client
                # When request target is absolute URI, net.peer.name MUST
                # match URI port identifier, otherwise it MUST match Host
                # header port identifier.
                'net.peer.name' => $uri->host,
                'net.peer.port' => $uri->port,

                # TODO: http.request_content_length will require us
                # to hook into write_request most likely
            },
        );

        my $res = $self->$code( $method, $url, $options );
        $span->set_attribute( 'http.status_code' => $res->{status} );

        # TODO: this should include retries
        $span->set_attribute( 'http.resend_count' => scalar @{ $res->{redirects} } )
            if $res->{redirects};

        unless ( $res->{success} ) {
            my $description = $res->{status} == 599 ? ( $res->{content} // '' ) : '';
            $span->set_status( SPAN_STATUS_ERROR, $description );
        }

        my $length = $res->{headers}{'content-length'};
        $span->set_attribute( 'http.response_content_length' => $length ) if defined $length;

        return $res;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

OpenTelemetry::Integration::HTTP::Tiny - OpenTelemetry integration for HTTP::Tiny

=head1 SYNOPSIS

    use OpenTelemetry::Integration 'HTTP::Tiny';
    HTTP::Tiny->new->get('https://metacpan.org');

=head1 DESCRIPTION

See L<OpenTelemetry::Integration> for more details.

Since this is a core module, it's included in the L<OpenTelemetry> core
distribution as well.

=head1 COPYRIGHT

...
