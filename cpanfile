requires 'Future', '0.26';         # Future->done
requires 'List::Util', '1.45';     # For uniq
requires 'Log::Any';
requires 'Object::Pad', '0.57';
requires 'Ref::Util';
requires 'Syntax::Keyword::Defer';
requires 'UUID::URandom';
requires 'X::Tiny';

on test => sub {
    requires 'Test2::V0';
    requires 'Class::Inspector'; # For OpenTelemetry::Integration test
};
