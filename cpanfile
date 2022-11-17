requires 'Object::Pad', '0.57';
requires 'UUID::URandom';
requires 'List::Util', '1.45'; # For uniq
requires 'X::Tiny';

on test => sub {
    requires 'Test2::V0';
};
