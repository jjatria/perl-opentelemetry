#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span';

use Scalar::Util 'refaddr';

is my $s = CLASS->new( name => 'foo' ), object { prop isa => CLASS },
    'Can create span';

my $self = refaddr $s;

is refaddr $s->set_name('bar'),         $self, 'set_name is chainable';
is refaddr $s->set_attribute( x => 1 ), $self, 'set_attribute is chainable';
is refaddr $s->set_status(0),           $self, 'set_status is chainable';
is refaddr $s->set_status(0, 'what'),   $self, 'set_status takes description';
is refaddr $s->add_link( x => 1),       $self, 'add_link is chainable';
is refaddr $s->add_event( x => 1),      $self, 'add_link is chainable';
is refaddr $s->end,                     $self, 'end is chainable';
is refaddr $s->end(123),                $self, 'end takes time';

done_testing;
