requires 'Object::Pad';
requires 'UUID::URandom';
requires 'List::Util', '1.45'; # For uniq

on test => sub {
    requires 'Test2::V0';
};
