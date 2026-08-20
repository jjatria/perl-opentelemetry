#!/usr/bin/env perl

use Test2::Require::Module 'DBI';
use Test2::V0 -target => 'OpenTelemetry::Instrumentation::DBI';
use experimental 'signatures';

use OpenTelemetry;
use OpenTelemetry::Constants -span;
use DBI;

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
                                return if defined $self->{otel}{status};

                                $self->{otel}{status} = {
                                    code => $status,
                                    $desc ? ( description => $desc ) : (),
                                };
                            },
                            record_exception => sub ( $self, $e, %attributes ) {
                                push @{ $self->{otel}{exceptions} //= [] }, {
                                    exception  => $e,
                                    attributes => \%attributes,
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

is [ CLASS->dependencies ], ['DBI'], 'Reports dependencies';

subtest Mem => sub {
    CLASS->uninstall;

    is +CLASS->install, T, 'Installed modifier';
    is +CLASS->install, F, 'Installed modifier once';

    my $db;

    subtest Connect => sub {
        subtest 'Bad DSN' => sub {
            like dies { DBI->connect('this is not a DSN') },
                qr/Can't connect to data source .* can't work out what driver to use/,
                'Cannot work out driver';

            is $span->{otel}, {
                exceptions => [
                    {
                        attributes => {},
                        exception => match qr/^Can't connect to data source/,
                    },
                ],
                status     => {
                    code => SPAN_STATUS_ERROR,
                    description => match qr/^Can't connect to data source/,
                },
                ended      => T,
                kind       => SPAN_KIND_CLIENT,
                name       => 'connect',
                attributes => {},
            }, 'Captured connect data';
        };

        subtest Dies => sub {
            like dies { DBI->connect('dbi:FakeyMcFakeFace(RaiseError=1):host=foo;port=1234') },
                qr|Can't locate DBD/FakeyMcFakeFace|,
                'Not a real DB';

            is $span->{otel}, {
                exceptions => [
                    {
                        attributes => {},
                        exception => match qr/install_driver\(FakeyMcFakeFace\) failed/,
                    },
                ],
                status     => {
                    code => SPAN_STATUS_ERROR,
                    description => match qr/install_driver\(FakeyMcFakeFace\) failed/,
                },
                ended      => T,
                kind       => SPAN_KIND_CLIENT,
                name       => 'connect',
                attributes => {
                    'server.address' => 'foo',
                    'server.port'    => 1234,
                },
            }, 'Captured connect data';
        };

        subtest Fails => sub {
            is warnings{
                is +DBI->connect('dbi:File:f_dir=/not/a/real/directory/deadbeef'), F,
                    'Could not connect';
            }, [
                match qr/DBI connect.* failed: No such directory/
            ], 'Failed connection warned';

            is $span->{otel}, {
                status     => {
                    code => SPAN_STATUS_ERROR,
                    description => match qr|No such directory .*/not/a/real/directory/deadbeef|,
                },
                ended      => T,
                kind       => SPAN_KIND_CLIENT,
                name       => 'connect',
                attributes => {},
            }, 'Captured connect data';
        };

        subtest Succeeds => sub {
            # NOTE: 'port' is not a valid attribute for DBD::Mem,
            # and setting it sets $db->err. However, we don't capture it
            # because it is not an error (= DBI->connect still returns
            # a handle you can use
            $db = DBI->connect('dbi:Mem:port=1234', undef, undef, { RaiseError => 1, PrintError => 0 } );
            is $span->{otel}, {
                status     => { code => SPAN_STATUS_OK },
                ended      => T,
                kind       => SPAN_KIND_CLIENT,
                name       => 'connect',
                attributes => {
                    'server.address' => U,
                    'server.port'    => 1234,
                },
            }, 'Captured connect data';
        };
    };

    like dies {
        $db->do('SELECT id FROM foo');
    }, qr/No such column 'id'/, 'Raised error';

    is $span->{otel}, {
        status => {
            code        => SPAN_STATUS_ERROR,
            description => match qr/No such column 'id'/,
        },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'SELECT id FROM foo',
        attributes => {
            'db.statement'   => 'SELECT id FROM foo',
            'server.address' => U,
            'server.port'    => 1234,
        },
    }, 'Captured error';

    $db->do('CREATE TABLE foo (id INT)');

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'CREATE TABLE foo (id INT)',
        attributes => {
            'db.statement'   => 'CREATE TABLE foo (id INT)',
            'server.address' => U,
            'server.port'    => 1234,
        },
    }, 'Captured create data';

    $db->do('INSERT INTO foo ( id ) VALUES ( 123 )');

    is $db->selectall_arrayref( 'SELECT * FROM foo WHERE id = ?', {}, '123' ),
        [ [123] ],
        'Read data';

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'SELECT * FROM foo WHERE id = ?',
        attributes => {
            'db.statement'   => 'SELECT * FROM foo WHERE id = ?',
            'server.address' => U,
            'server.port'    => 1234,
        },
    }, 'Captured select data';

    my $sth = $db->prepare('SELECT * FROM foo WHERE id = ?');
    my $mock = mock $sth, override => [ finish => sub { die 'boom' } ];

    like dies { $sth->execute('secret') },
        match qr/boom/,
        'Exception propagates';

    is $span->{otel}, {
        status     => {
            code        => SPAN_STATUS_ERROR,
            description => 'boom',
        },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'SELECT * FROM foo WHERE id = ?',
        attributes => {
            'db.statement'   => 'SELECT * FROM foo WHERE id = ?',
            'server.address' => U,
            'server.port'    => 1234,
        },
        exceptions => [
            {
                exception  => match qr/^boom at \S+ line \d+\.$/a,
                attributes => {},
            },
        ],
    }, 'Captured exception';
};

done_testing;
