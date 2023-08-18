#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span';

is my $s = CLASS->new( name => 'foo' ), object { prop isa => CLASS },
    'Can create span';

ref_is $s->add_event( x => 1),            $s, 'add_link is chainable';
ref_is $s->add_event,                     $s, 'add_event call can be empty';
ref_is $s->add_link( x => 1),             $s, 'add_link is chainable';
ref_is $s->add_link,                      $s, 'add_link call can be empty';
ref_is $s->end(123),                      $s, 'end takes time';
ref_is $s->end,                           $s, 'end is chainable';
ref_is $s->record_exception( 1, a => 1 ), $s, 'record_exception takes pairs';
ref_is $s->record_exception(1),           $s, 'record_exception takes error';
ref_is $s->set_attribute,                 $s, 'set_attribute call can be empty';
ref_is $s->set_attribute( x => 1 ),       $s, 'set_attribute is chainable';
ref_is $s->set_name('bar'),               $s, 'set_name is chainable';
ref_is $s->set_status(0),                 $s, 'set_status is chainable';
ref_is $s->set_status(0, 'what'),         $s, 'set_status takes description';

like dies { $s->set_name },
    qr/^Too few arguments/,
    'set_name requires arguments';

like dies { $s->set_status },
    qr/^Too few arguments/,
    'set_status requires arguments';

like dies { $s->record_exception },
    qr/^Too few arguments/,
    'record_exception requires arguments';

done_testing;
