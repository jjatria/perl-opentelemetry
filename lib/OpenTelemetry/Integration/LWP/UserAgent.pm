package OpenTelemetry::Integration::LWP::UserAgent;
# ABSTRACT: OpenTelemetry integration for LWP::UserAgent

our $VERSION = '0.017';

use strict;
use warnings;
use experimental 'signatures';

use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Try;
use Syntax::Keyword::Dynamically;
use List::Util 'none';
use OpenTelemetry::Constants qw( SPAN_KIND_CLIENT SPAN_STATUS_ERROR SPAN_STATUS_OK );
use OpenTelemetry::Context;
use OpenTelemetry::Trace;
use OpenTelemetry;

use parent 'OpenTelemetry::Integration';

sub dependencies { 'LWP::UserAgent' }

my sub get_headers ( $have, $want, $prefix ) {
    return unless @$want;

    my %attributes;
    $have->scan( sub ( $key, $value ) {
        $key =~ tr/-/_/;
        return if none { $key =~ $_ } @$want;
        push @{ $attributes{ $prefix . '.' . lc $key } //= [] }, $value;
    });

    %attributes;
}

my ( $original, $loaded );

sub uninstall ( $class ) {
    return unless $loaded;
    no strict 'refs';
    no warnings 'redefine';
    delete $Class::Method::Modifiers::MODIFIER_CACHE{'LWP::UserAgent'}{request};
    *{'LWP::UserAgent::request'} = $original;
    undef $loaded;
    return;
}

sub install ( $class, %config ) {
    return if $loaded;
    return unless Class::Inspector->loaded('LWP::UserAgent');

    my @wanted_request_headers = map qr/^\Q$_\E$/i, map tr/-/_/r,
        @{ delete $config{request_headers}  // [] };

    my @wanted_response_headers = map qr/^\Q$_\E$/i, map tr/-/_/r,
        @{ delete $config{response_headers} // [] };

    $original = \&LWP::UserAgent::request;
    install_modifier 'LWP::UserAgent' => around => request => sub {
        my ( $code, $self, $request, @rest ) = @_;

        my $uri    = $request->uri->clone;
        my $method = $request->method;
        my $length = length $request->content;

        $uri->userinfo('REDACTED:REDACTED') if $uri->userinfo;

        my $span = OpenTelemetry->tracer_provider->tracer(
            name    => __PACKAGE__,
            version => $VERSION,
        )->create_span(
            name       => $method,
            kind       => SPAN_KIND_CLIENT,
            attributes => {
                # As per https://github.com/open-telemetry/semantic-conventions/blob/main/docs/http/http-spans.md
                'http.request.method'      => $method,
                'network.protocol.name'    => 'http',
                'network.protocol.version' => '1.1',
                'network.transport'        => 'tcp',
                'server.address'           => $uri->host,
                'server.port'              => $uri->port,
                'url.full'                 => "$uri", # redacted
                'user_agent.original'      => $self->agent,

                # This does not include auto-generated headers
                # Capturing those would require to hook into the
                # handle's write_request method
                get_headers(
                    $self->default_headers,
                    \@wanted_request_headers,
                    'http.request.header'
                ),

                get_headers(
                    $request->headers,
                    \@wanted_request_headers,
                    'http.request.header'
                ),

                # Request body can be generated with a data_callback
                # parameter, in which case we don't set this attribute
                # Setting it would likely involve us hooking into the
                # handle's write_body method
                $length ? ( 'http.request.body.size' => $length ) : (),
            },
        );

        dynamically OpenTelemetry::Context->current
            = OpenTelemetry::Trace->context_with_span($span);

        try {
            my $response = $self->$code( $request, @rest );
            $span->set_attribute( 'http.response.status_code' => $response->code );

            # TODO: this should include retries
            if ( my $count = $response->redirects ) {
                $span->set_attribute( 'http.resend_count' => $count )
            }

            my $length = $response->header('content-length');
            $span->set_attribute( 'http.response.body.size' => $length )
                if defined $length;

            if ( $response->is_success ) {
                $span->set_status( SPAN_STATUS_OK );
            }
            else {
                $span->set_status( SPAN_STATUS_ERROR, $response->code );
            }

            $span->set_attribute(
                get_headers(
                    $response->headers,
                    \@wanted_response_headers,
                    'http.response.header'
                )
            );

            return $response;
        }
        catch ($error) {
            my ($description) = split /\n/, $error =~ s/^\s+|\s+$//gr, 2;
            $description =~ s/ at \S+ line \d+\.$//a;

            $span->record_exception($error);
            $span->set_status( SPAN_STATUS_ERROR, $description );

            die $error;
        }
        finally {
            $span->end;
        }
    };

    return $loaded = 1;
}

1;
