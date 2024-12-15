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

    my $db = DBI->connect('dbi:Mem:(RaiseError=1):port=1234;');

    is +CLASS->install, T, 'Installed modifier';
    is +CLASS->install, F, 'Installed modifier once';

    like warnings { $db->do('SELECT id FROM foo') } => [], 'Captured warnings';

    is $span->{otel}, {
        status => {
            code        => SPAN_STATUS_ERROR,
            description => match qr/No such column 'id'/,
        },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'SELECT id FROM foo',
        attributes => {
            'db.connection_string' => '(RaiseError=1):port=1234;',
            'db.statement'   => 'SELECT id FROM foo',
            'db.system'      => 'mem',
            'db.user'        => U,
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
            'db.connection_string' => '(RaiseError=1):port=1234;',
            'db.statement'   => 'CREATE TABLE foo (id INT)',
            'db.system'      => 'mem',
            'db.user'        => U,
            'server.address' => U,
            'server.port'    => 1234,
        },
    }, 'Captured create data';

    $db->selectall_arrayref('
        SELECT *
          FROM foo
         WHERE id = ?
    ', {}, 'secret');

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'SELECT * FROM foo WHERE id = ?',
        attributes => {
            'db.connection_string' => '(RaiseError=1):port=1234;',
            'db.statement'   => 'SELECT * FROM foo WHERE id = ?',
            'db.system'      => 'mem',
            'db.user'        => U,
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
            'db.connection_string' => '(RaiseError=1):port=1234;',
            'db.statement'   => 'SELECT * FROM foo WHERE id = ?',
            'db.system'      => 'mem',
            'db.user'        => U,
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
