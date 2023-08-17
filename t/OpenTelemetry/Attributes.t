#!/usr/bin/env perl

use Test2::V0;
use Object::Pad;
use OpenTelemetry::Test::Logs;

class Local::Test :does(OpenTelemetry::Attributes) { }

is Local::Test->new, object {
    call attributes         => {};
    call dropped_attributes => 0;
}, 'Role provides basic methods';

is my $a = Local::Test->new( attributes => { foo => 123, bar => 234 } ), object {
    call attributes         => { foo => 123, bar => 234 };
    call dropped_attributes => 0;
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
    call dropped_attributes  => 0;
}, 'Can limit attribute length';

subtest Arrayref => sub {
    my $array = [ 1, 2, 3 ];
    my $x = Local::Test->new( attributes => { list => $array } );
    push @$array, 'fake';
    is $x->attributes->{list}, [ 1, 2, 3 ], 'Cannot write to arrayref values';
};

subtest Limits => sub {
    subtest Count => sub {
        OpenTelemetry::Test::Logs->clear;

        my $a = Local::Test->new( attribute_count_limit => 2 );

        is $a->_set_attribute( foo => 123 ), object {
            call sub { shift->attributes->{foo} } => 123;
            call dropped_attributes => 0;
        }, 'Can store attributes below limit';

        is $a->_set_attribute( bar => 234 ), object {
            call sub { shift->attributes->{bar} } => 234;
            call dropped_attributes => 0;
        }, 'Can record attributes to limit';

        is $a->_set_attribute( baz => 345 ), object {
            call sub { shift->attributes->{baz} } => U;
            call dropped_attributes => 1;
        }, 'Dropped attribute and recorded it';

        is $a->_set_attribute( baz => 345, boom => 456 ), object {
            call sub { [ @{ shift->attributes }{qw( baz boom )} ] } => [ U, U ];
            call dropped_attributes => 3;
        }, 'Dropped attributes and recorded them';

        is $a->_set_attribute( foo => 345 ), object {
            call sub { shift->attributes->{foo} } => 345;
            call dropped_attributes => 3;
        }, 'Can still replace existing attribute';

        is $a->_set_attribute( foo => undef ), object {
            call sub { shift->attributes->{foo} } => 345;
            call dropped_attributes => 4;
        }, 'Dropped attribute does not overwrite';

        is +OpenTelemetry::Test::Logs->messages, [
            [ debug => OpenTelemetry => match qr/1 attribute entry because it/ ],
            [ debug => OpenTelemetry => match qr/2 attribute entries because they/ ],
            [ debug => OpenTelemetry => match qr/1 attribute entry .* limit \(2\)/ ],
        ], 'Logged dropped attributes';
    };

    subtest Length => sub {
        OpenTelemetry::Test::Logs->clear;

        my $a = Local::Test->new( attribute_length_limit => 4 );

        is $a->_set_attribute( foo => 123 ), object {
            call sub { shift->attributes->{foo} } => 123;
            call dropped_attributes => 0;
        }, 'Set short attribute';

        is $a->_set_attribute( foo => 1234 ), object {
            call sub { shift->attributes->{foo} } => 1234;
            call dropped_attributes => 0;
        }, 'Set attribute at limit';

        is $a->_set_attribute( foo => 12345 ), object {
            call sub { shift->attributes->{foo} } => 1234;
            call dropped_attributes => 0;
        }, 'Set longer attribute';

        is $a->_set_attribute( foo => [ 123, 1234, 12345, undef ] ), object {
            call sub { shift->attributes->{foo} } => [ 123, 1234, 1234, undef ];
            call dropped_attributes => 0;
        }, 'Applied limit to each value in an array reference';

        is +OpenTelemetry::Test::Logs->messages, [ ], 'Nothing logged';
    };
};

subtest 'Value validation' => sub {
    OpenTelemetry::Test::Logs->clear;

    my $test = sub {
        my $x = Local::Test
            ->new( attributes => { x => shift } );

        [ $x->attributes->{x}, $x->dropped_attributes ];
    };

    subtest Valid => sub {
        is $test->( 'string' ), [ 'string', 0 ], 'String';
        is $test->(  123456  ), [  123456 , 0 ], 'Integer';
        is $test->(  123.56  ), [  123.56 , 0 ], 'Float';
        is $test->(       0  ), [       0 , 0 ], 'Zero';

        # NOTE: We cannot validate types in Perl
        is $test->( [ 1, undef, 'string', 4 ] ),
            [ [ 1, undef, 'string', 4 ], 0 ],
            'Array reference';
    };

    subtest Invalid => sub {
        is $test->(undef),           [ U, 1 ], 'Undef';
        is $test->({}),              [ U, 1 ], 'Hash reference';
        is $test->([ 1, {}, 3 ]),    [ U, 1 ], 'Array reference with reference';
    };

    is +OpenTelemetry::Test::Logs->messages, [
        [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
        [ trace => OpenTelemetry => 'Attribute values cannot be references' ],
        [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
        [ trace => OpenTelemetry => match qr/themselves hold references/ ],
        [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
    ], 'Logged invalid attributes';
};

done_testing;
