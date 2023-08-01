requires 'Bytes::Random::Secure';
requires 'Class::Method::Modifiers';
requires 'Future', '0.26'; # For Future->done
requires 'Future::AsyncAwait';
requires 'List::Util', '1.45'; # For uniq
requires 'Log::Any';
requires 'Module::Pluggable';
requires 'Mutex';
requires 'Object::Pad', '0.74'; # For //= field initialisers
requires 'Ref::Util';
requires 'Syntax::Keyword::Defer';
requires 'URI';
requires 'URL::Encode';
requires 'UUID::URandom';
requires 'X::Tiny';
requires 'namespace::clean';

on test => sub {
    requires 'Test2::V0';
    requires 'Class::Inspector'; # For OpenTelemetry::Integration test
};
