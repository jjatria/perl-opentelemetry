#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::OpenTelemetry;

use Object::Pad ':experimental(mop)';
class Local::Test :does(OpenTelemetry::Attributes) { }

# Here to ensure downstream uses do not break
class Local::Test::Writable :does(OpenTelemetry::Attributes) {
    method write (%new) {
        Object::Pad::MOP::Class->for_class('OpenTelemetry::Attributes')
            ->get_field('$attributes')
            ->value($self)
            ->set(%new);
        $self;
    }
}

is +Local::Test->new, object {
    call attributes         => {};
    call dropped_attributes => 0;
}, 'Role provides basic methods';

is my $a = Local::Test->new( attributes => { foo => 123, bar => 234 } ), object {
    call attributes         => { foo => 123, bar => 234 };
    call dropped_attributes => 0;
}, 'Can pass attributes on construction';

$a->attributes->{fake} = 1234;

is $a->attributes->{fake}, U, 'Attributes are immutable';

is +Local::Test->new(
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
        my $a = Local::Test::Writable->new( attribute_count_limit => 2 );

        no_messages {
            is $a->write( foo => 123 ), object {
                call sub { shift->attributes->{foo} } => 123;
                call dropped_attributes => 0;
            }, 'Can store attributes below limit';
        };

        no_messages {
            is $a->write( bar => 234 ), object {
                call sub { shift->attributes->{bar} } => 234;
                call dropped_attributes => 0;
            }, 'Can record attributes to limit';
        };

        is messages {
            is $a->write( baz => 345 ), object {
                call sub { shift->attributes->{baz} } => U;
                call dropped_attributes => 1;
            }, 'Dropped attribute and recorded it';
        } => [
            [ debug => OpenTelemetry => match qr/1 attribute entry because it/ ],
        ], 'Logged messages';

        is messages {
            is $a->write( baz => 345, boom => 456 ), object {
                call sub { [ @{ shift->attributes }{qw( baz boom )} ] } => [ U, U ];
                call dropped_attributes => 3;
            }, 'Dropped attributes and recorded them';
        } => [
            [ debug => OpenTelemetry => match qr/2 attribute entries because they/ ],
        ], 'Logged messages';

        no_messages {
            is $a->write( foo => 345 ), object {
                call sub { shift->attributes->{foo} } => 345;
                call dropped_attributes => 3;
            }, 'Can still replace existing attribute';
        };

        is messages {
            is $a->write( foo => undef ), object {
                call sub { shift->attributes->{foo} } => 345;
                call dropped_attributes => 4;
            }, 'Dropped attribute does not overwrite';
        } => [
            [ debug => OpenTelemetry => match qr/1 attribute entry .* limit \(2\)/ ],
        ], 'Logged messages';
    };

    subtest Length => sub {
        my $a = Local::Test::Writable->new( attribute_length_limit => 4 );

        no_messages {
            is $a->write( foo => 123 ), object {
                call sub { shift->attributes->{foo} } => 123;
                call dropped_attributes => 0;
            }, 'Set short attribute';

            is $a->write( foo => 1234 ), object {
                call sub { shift->attributes->{foo} } => 1234;
                call dropped_attributes => 0;
            }, 'Set attribute at limit';

            is $a->write( foo => 12345 ), object {
                call sub { shift->attributes->{foo} } => 1234;
                call dropped_attributes => 0;
            }, 'Set longer attribute';

            is $a->write( foo => [ 123, 1234, 12345, undef ] ), object {
                call sub { shift->attributes->{foo} } => [ 123, 1234, 1234, undef ];
                call dropped_attributes => 0;
            }, 'Applied limit to each value in an array reference';
        };
    };
};

subtest 'Validation' => sub {
    my $test = sub {
        my $x = Local::Test
            ->new( attributes => { x => shift } );

        [ $x->attributes->{x}, $x->dropped_attributes ];
    };

    subtest 'Valid value' => sub {
        no_messages {
            is $test->( 'string' ), [ 'string', 0 ], 'String';
            is $test->(  123456  ), [  123456 , 0 ], 'Integer';
            is $test->(  123.56  ), [  123.56 , 0 ], 'Float';
            is $test->(       0  ), [       0 , 0 ], 'Zero';

            # NOTE: We cannot validate types in Perl
            is $test->( [ 1, undef, 'string', 4 ] ),
                [ [ 1, undef, 'string', 4 ], 0 ],
                'Array reference';
        };
    };

    subtest 'Invalid value' => sub {
        is messages {
            is $test->(undef),        [ U, 1 ], 'Undef';
            is $test->({}),           [ U, 1 ], 'Hash reference';
            is $test->([ 1, {}, 3 ]), [ U, 1 ], 'Array reference with reference';
        } => [
            [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
            [ trace => OpenTelemetry => 'Attribute values cannot be references' ],
            [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
            [ trace => OpenTelemetry => match qr/themselves hold references/ ],
            [ debug => OpenTelemetry => match qr/Dropped 1 attribute/ ],
        ] => 'Logged invalid attributes';
    };

    subtest 'Invalid key' => sub {
        is messages {
            is +Local::Test->new( attributes => { '' => 123 } ), object {
                call attributes => { null => 123 };
            }, 'Defaulted empty key';
        } => [
            [ debug => OpenTelemetry => match qr/Setting to 'null'/ ],
        ] => 'Logged invalid attributes';
    };
};

done_testing;
