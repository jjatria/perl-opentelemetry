use Object::Pad;
# ABSTRACT: The OpenTelemetry Span abstract interface

package OpenTelemetry::Trace::Span::Role;

our $VERSION = '0.001';

role OpenTelemetry::Trace::Span::Role {
    # Returns a bool
    method recording;

    # Returns span context
    method context;

    # Takes hash, returns self
    method set_attribute ( %args ) { $self }

    # Takes name, returns self
    method set_name ( $name ) { $self }

    # Takes name and optional description, returns self
    method set_status ( $status, $description = '' ) { $self }

    # Takes single link data, returns self
    method add_link ( %args ) { $self }

    # Takes single event data, returns self
    method add_event ( %args ) { $self }

    # Takes an optional timestamp, returns self
    method end ( $timestamp = time ) { $self }
}
