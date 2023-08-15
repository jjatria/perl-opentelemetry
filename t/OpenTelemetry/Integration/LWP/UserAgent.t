#!/usr/bin/env perl

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'HTTP::Response';
use Test2::Require::Module 'HTTP::Headers';
use Test2::Require::Module 'HTTP::Request::Common';

use Test2::V0 -target => 'OpenTelemetry::Integration::LWP::UserAgent';
use experimental 'signatures';

use OpenTelemetry;
use OpenTelemetry::Constants -span_status, -span_kind;
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

    ok +OpenTelemetry::Integration::LWP::UserAgent->install,
        'Installed modifier';

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

# subtest 'HTTP error' => sub {
#     CLASS->uninstall;
#
#     my $http = mock 'HTTP::Tiny' => override => [
#         request => sub { { success => '', status => 404 } },
#     ];
#
#     ok +OpenTelemetry::Integration::HTTP::Tiny->install,
#         'Installed modifier';
#
#     my $ua = HTTP::Tiny->new;
#
#     like $ua->get('http://fa.ke/404'), { success => F },
#         'Can request';
#
#     is $span->{otel}, {
#         status     => {
#             code        => SPAN_STATUS_ERROR,
#             description => 404,
#         },
#         ended      => T,
#         kind       => SPAN_KIND_CLIENT,
#         name       => 'GET',
#         attributes => {
#             'http.request.method'       => 'GET',
#             'http.response.status_code' => 404,
#             'network.protocol.name'     => 'http',
#             'network.protocol.version'  => '1.1',
#             'network.transport'         => 'tcp',
#             'server.address'            => 'fa.ke',
#             'server.port'               => 80,
#             'url.full'                  => 'http://fa.ke/404',
#             'user_agent.original'       => $ua->agent,
#         },
#     }, 'Captured basic data';
# };
#
# subtest 'Internal error' => sub {
#     CLASS->uninstall;
#
#     my $http = mock 'HTTP::Tiny' => override => [
#         request => sub { { success => '', status => 599, content => 'boom' } },
#     ];
#
#     ok +OpenTelemetry::Integration::HTTP::Tiny->install,
#         'Installed modifier';
#
#     my $ua = HTTP::Tiny->new;
#
#     like $ua->get('http://fa.ke/599'), { success => F },
#         'Can request';
#
#     is $span->{otel}, {
#         status     => {
#             code        => SPAN_STATUS_ERROR,
#             description => 'boom',
#         },
#         ended      => T,
#         kind       => SPAN_KIND_CLIENT,
#         name       => 'GET',
#         attributes => {
#             'http.request.method'       => 'GET',
#             'http.response.status_code' => 599,
#             'network.protocol.name'     => 'http',
#             'network.protocol.version'  => '1.1',
#             'network.transport'         => 'tcp',
#             'server.address'            => 'fa.ke',
#             'server.port'               => 80,
#             'url.full'                  => 'http://fa.ke/599',
#             'user_agent.original'       => $ua->agent,
#         },
#     }, 'Captured basic data';
# };
#
# subtest 'Requested headers' => sub {
#     CLASS->uninstall;
#
#     my $http = mock 'HTTP::Tiny' => override => [
#         request => sub {
#             {
#                 success => 'TEST',
#                 status  => 123,
#                 headers => {
#                     Response_1 => 1,
#                     ReSponse_2 => [ 2, 'two' ],
#                     response_3 => 3,
#                 },
#                 redirects => [
#                     {},
#                     {},
#                     {},
#                 ]
#             }
#         },
#     ];
#
#     ok +OpenTelemetry::Integration::HTTP::Tiny->install(
#         request_headers  => [qw( default-1 default-2 request_2 request_3 )],
#         response_headers => [qw( response_1 response_[0-9] )],
#     ) => 'Installed modifier';
#
#     my $ua = HTTP::Tiny->new(
#         default_headers => {
#             'Default-1' => [ 1, 'one' ],
#             'DeFault-2' => 2,
#             'DEFAULT-3' => 3,
#         },
#     );
#
#     like $ua->get(
#         'http://fa.ke/path?query=1#fragment' => {
#             headers => {
#                 Request_1 => 1,
#                 ReQuest_2 => 2,
#                 request_3 => [ 3, 'three' ],
#             },
#         },
#     ) => { success => 'TEST' } => 'Can request';
#
#     is $span->{otel}, {
#         status     => { code => SPAN_STATUS_OK },
#         ended      => T,
#         kind       => SPAN_KIND_CLIENT,
#         name       => 'GET',
#         attributes => {
#             'http.request.header.default_1'   => [ 1, 'one' ],
#             'http.request.header.default_2'   => [ 2 ],
#             'http.request.header.request_2'   => [ 2 ],
#             'http.request.header.request_3'   => [ 3, 'three' ],
#             'http.request.method'             => 'GET',
#             'http.resend_count'               => 3,
#             'http.response.header.response_1' => [ 1 ],
#             'http.response.status_code'       => 123,
#             'network.protocol.name'           => 'http',
#             'network.protocol.version'        => '1.1',
#             'network.transport'               => 'tcp',
#             'server.address'                  => 'fa.ke',
#             'server.port'                     => 80,
#             'url.full'                        => 'http://fa.ke/path?query=1#fragment',
#             'user_agent.original'             => $ua->agent,
#         },
#     }, 'Captured basic data';
# };

done_testing;
