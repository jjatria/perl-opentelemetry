requires 'Bytes::Random::Secure';
requires 'Class::Method::Modifiers';
requires 'Exporter::Tiny', '0.044'; # For -as => CODE support
requires 'Feature::Compat::Defer';
requires 'Feature::Compat::Try', '0.05'; # For finally before 5.35
requires 'Future', '0.26'; # For Future->done
requires 'Future::AsyncAwait';
requires 'List::Util', '1.45'; # For uniq
requires 'Log::Any';
requires 'Module::Pluggable';
requires 'Module::Runtime';
requires 'Mutex';
requires 'Object::Pad', '0.74'; # For //= field initialisers
requires 'Ref::Util';
requires 'Sentinel';
requires 'Syntax::Keyword::Dynamically';
requires 'URI';
requires 'URL::Encode';
requires 'UUID::URandom';
requires 'X::Tiny';

on test => sub {
    requires 'Class::Inspector'; # For OpenTelemetry::Instrumentation test
    requires 'Metrics::Any';
    requires 'Test2::V0';
};
