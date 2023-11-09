#!/usr/bin/env perl

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'HTTP::Response';
use Test2::Require::Module 'HTTP::Headers';
use Test2::Require::Module 'HTTP::Request::Common';

use Test2::V0 -target => 'OpenTelemetry::Integration::LWP::UserAgent';
use experimental 'signatures';

use OpenTelemetry;
use OpenTelemetry::Constants -span;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request::Common;

my $span;
my $otel = mock OpenTelemetry => override => [
    tracer_provider => sub {
        mock {} => add => [
            tracer => sub {
                mock {} => add => [
                    create_span => sub ( $, %args ) {
                        $span = mock { otel => \%args } => add => [
                            set_attribute => sub ( $self, %args ) {
                                $self->{otel}{attributes} = {
                                    %{ $self->{otel}{attributes} // {} },
                                    %args,
                                };
                            },
                            set_status => sub ( $self, $status, $desc = '' ) {
                                $self->{otel}{status} = {
                                    code => $status,
                                    $desc ? ( description => $desc ) : (),
                                };
                            },
                            end => sub ( $self ) {
                                $self->{otel}{ended} = 1;
                            },
                            record_exception => sub ( $self, $exception ) {
                                push @{ $self->{otel}{events} //= [] }, {
                                    exception => $exception,
                                };
                            },
                        ];
                    },
                ];
            },
        ];
    },
];

is [ CLASS->dependencies ], ['LWP::UserAgent'], 'Reports dependencies';

subtest 'No headers' => sub {
    CLASS->uninstall;

    my $http = mock 'LWP::UserAgent' => override => [
        request => sub {
            HTTP::Response->new(
                204,
                'This is a test',
                HTTP::Headers->new(
                    'content-length' => 5,
                ),
            );
        },
    ];

    ok +CLASS->install, 'Installed modifier';

    my $ua =LWP::UserAgent->new;

    is $ua->request( POST 'http://user:password@fa.ke', Content => '0123456789' ),
        object {
            call message => 'This is a test';
        },
        'Can request';

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'POST',
        attributes => {
            'http.request.body.size'    => 10,
            'http.request.method'       => 'POST',
            'http.response.status_code' => 204,
            'http.response.body.size'   => 5,
            'network.protocol.name'     => 'http',
            'network.protocol.version'  => '1.1',
            'network.transport'         => 'tcp',
            'server.address'            => 'fa.ke',
            'server.port'               => 80,
            'url.full'                  => 'http://REDACTED:REDACTED@fa.ke',
            'user_agent.original'       => $ua->agent,
        },
    }, 'Captured basic data';
};

subtest 'HTTP error' => sub {
    CLASS->uninstall;

    my $http = mock 'LWP::UserAgent' => override => [
        request => sub { HTTP::Response->new( 404, 'TEST' ) },
    ];

    ok +CLASS->install, 'Installed modifier';

    my $ua = LWP::UserAgent->new;

    like $ua->get('http://fa.ke/404'), object { call message => 'TEST' },
        'Can request';

    is $span->{otel}, {
        status     => {
            code        => SPAN_STATUS_ERROR,
            description => 404,
        },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'GET',
        attributes => {
            'http.request.method'       => 'GET',
            'http.response.status_code' => 404,
            'network.protocol.name'     => 'http',
            'network.protocol.version'  => '1.1',
            'network.transport'         => 'tcp',
            'server.address'            => 'fa.ke',
            'server.port'               => 80,
            'url.full'                  => 'http://fa.ke/404',
            'user_agent.original'       => $ua->agent,
        },
    }, 'Captured basic data';
};

subtest 'Internal error' => sub {
    CLASS->uninstall;

    my $http = mock 'LWP::UserAgent' => override => [
        request => sub { die 'boom' },
    ];

    ok +CLASS->install, 'Installed modifier';

    my $ua = LWP::UserAgent->new;

    like dies { $ua->get('http://fa.ke/599') }, qr/^boom/,
        'Exception is not caught';

    is $span->{otel}, {
        status     => {
            code        => SPAN_STATUS_ERROR,
            description => match qr/^boom/,
        },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'GET',
        attributes => {
            'http.request.method'       => 'GET',
            'network.protocol.name'     => 'http',
            'network.protocol.version'  => '1.1',
            'network.transport'         => 'tcp',
            'server.address'            => 'fa.ke',
            'server.port'               => 80,
            'url.full'                  => 'http://fa.ke/599',
            'user_agent.original'       => $ua->agent,
        },
        events => [
            { exception => match qr/^boom/ },
        ],
    }, 'Captured basic data';
};

subtest 'Requested headers' => sub {
    CLASS->uninstall;

    my $http = mock 'LWP::UserAgent' => override => [
        request => sub {
            HTTP::Response->new(
                204,
                'TEST',
                HTTP::Headers->new(
                    Response_1 => 1,
                    ReSponse_2 => [ 2, 'two' ],
                    response_3 => 3,
                ),
            );
        },
    ];

    ok +CLASS->install(
        request_headers  => [qw( default-1 default-2 request_2 request_3 )],
        response_headers => [qw( response_1 response_[0-9] )],
    ) => 'Installed modifier';

    my $ua = LWP::UserAgent->new(
        default_headers => HTTP::Headers->new(
            'Default-1' => [ 1, 'one' ],
            'DeFault-2' => 2,
            'DEFAULT-3' => 3,
        ),
    );

    like $ua->get(
        'http://fa.ke/path?query=1#fragment' => (
            Request_1 => 1,
            ReQuest_2 => 2,
            request_3 => [ 3, 'three' ],
        ),
    ) => object { call message => 'TEST' } => 'Can request';

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'GET',
        attributes => {
            'http.request.header.default_1'   => [ 1, 'one' ],
            'http.request.header.default_2'   => [ 2 ],
            'http.request.header.request_2'   => [ 2 ],
            'http.request.header.request_3'   => [ 3, 'three' ],
            'http.request.method'             => 'GET',
            'http.response.header.response_1' => [ 1 ],
            'http.response.status_code'       => 204,
            'network.protocol.name'           => 'http',
            'network.protocol.version'        => '1.1',
            'network.transport'               => 'tcp',
            'server.address'                  => 'fa.ke',
            'server.port'                     => 80,
            'url.full'                        => 'http://fa.ke/path?query=1#fragment',
            'user_agent.original'             => $ua->agent,
        },
    }, 'Captured basic data';
};

done_testing;
