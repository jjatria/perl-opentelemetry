#!/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Trace::Span';

is my $self = CLASS->new( name => 'foo' ), object { prop isa => CLASS },
    'Can create span';

ref_is $self->set_name('bar'),         $self, 'set_name is chainable';
ref_is $self->set_attribute( x => 1 ), $self, 'set_attribute is chainable';
ref_is $self->set_status(0),           $self, 'set_status is chainable';
ref_is $self->set_status(0, 'what'),   $self, 'set_status takes description';
ref_is $self->add_link( x => 1),       $self, 'add_link is chainable';
ref_is $self->add_event( x => 1),      $self, 'add_link is chainable';
ref_is $self->end,                     $self, 'end is chainable';
ref_is $self->end(123),                $self, 'end takes time';

done_testing;
