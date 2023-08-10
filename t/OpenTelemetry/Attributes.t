#!/usr/bin/env perl

use Test2::V0;
use Object::Pad;
use OpenTelemetry::Test::Logs;

class Local::Test :does(OpenTelemetry::Attributes) { }

is Local::Test->new, object {
    call attributes          => {};
    call recorded_attributes => 0;
    call dropped_attributes  => 0;
}, 'Role provides basic methods';

is my $a = Local::Test->new( attributes => { foo => 123, bar => 234 } ), object {
    call attributes          => { foo => 123, bar => 234 };
    call recorded_attributes => 2;
    call dropped_attributes  => 0;
}, 'Can pass attributes on construction';

$a->attributes->{fake} = 1234;

is $a->attributes->{fake}, U, 'Attributes are immutable';

is Local::Test->new(
    attribute_length_limit => 4,
    attributes => {
        short => 123,
        right => 1234,
        long  => 12345,
        array => [
            123,
            123456789,
            1234,
            12345
        ],
    },
) => object {
    call attributes => {
        short => 123,
        right => 1234,
        long  => 1234,
        array => [
            123,
            1234,
            1234,
            1234,
        ],
    };
    call recorded_attributes => 4;
    call dropped_attributes  => 0;
}, 'Can limit attribute length';

subtest Limits => sub {
    OpenTelemetry::Test::Logs->clear;

    my $a = Local::Test->new( attribute_count_limit => 2 );

    is $a->_set_attribute( foo => 123 ), object {
        call sub { shift->attributes->{foo} } => 123;
        call recorded_attributes => 1;
        call dropped_attributes  => 0;
    }, 'Can record attributes below limit';

    is $a->_set_attribute( bar => 234 ), object {
        call sub { shift->attributes->{bar} } => 234;
        call recorded_attributes => 2;
        call dropped_attributes  => 0;
    }, 'Can record attributes to limit';

    is $a->_set_attribute( baz => 345 ), object {
        call sub { shift->attributes->{baz} } => U;
        call recorded_attributes => 3;
        call dropped_attributes  => 1;
    }, 'Dropped attribute and recorded it';

    is $a->_set_attribute( baz => 345, boom => 456 ), object {
        call sub { [ @{ shift->attributes }{qw( baz boom )} ] } => [ U, U ];
        call recorded_attributes => 5;
        call dropped_attributes  => 3;
    }, 'Dropped attributes and recorded them';

    is $a->_set_attribute( foo => 345 ), object {
        call sub { shift->attributes->{foo} } => 345;
        call recorded_attributes => 5;
        call dropped_attributes  => 3;
    }, 'Can still replace existing attribute';

    is +OpenTelemetry::Test::Logs->messages, [
        [ warning => OpenTelemetry => match qr/1 attribute entry because it/ ],
        [ warning => OpenTelemetry => match qr/2 attribute entries because they/ ],
    ], 'Logged dropped attributes';
};

subtest 'Validates values' => sub {
    OpenTelemetry::Test::Logs->clear;

    my $test = sub {
        my $x = Local::Test
            ->new( attributes => { x => shift } );

        [ $x->attributes->{x}, scalar keys %{ $x->attributes } ]
    };

    # Valid
    is $test->( 'string' ), [ 'string', 1 ], 'String';
    is $test->(  123456  ), [  123456 , 1 ], 'Integer';
    is $test->(  123.56  ), [  123.56 , 1 ], 'Float';
    is $test->(       0  ), [       0 , 1 ], 'Zero';

    # NOTE: We cannot validate types in Perl
    is $test->( [ 1, 'string', 4 ] ),
        [ [ 1, 'string', 4 ], 1 ],
        'Array reference';

    # Invalid
    is $test->(undef),           [ U, 0 ], 'Undef';
    is $test->({}),              [ U, 0 ], 'Hash reference';
    is $test->([ 1, {}, 3 ]),    [ U, 0 ], 'Array reference with reference';
    is $test->([ 1, undef, 3 ]), [ U, 0 ], 'Array reference with invalid value';

    is +OpenTelemetry::Test::Logs->messages, [
        [ warning => OpenTelemetry => 'Attribute values cannot be undefined' ],
        [ warning => OpenTelemetry => 'Attribute values cannot be hash references' ],
        [ warning => OpenTelemetry => match qr/hold references or undefined/ ],
        [ warning => OpenTelemetry => match qr/hold references or undefined/ ],
    ], 'Logged invalid attributes';
};

done_testing;
