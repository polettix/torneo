requires 'Mojolicious';
requires 'Mojolicious::Plugin::Authentication';
requires 'IO::Socket::SSL';
requires 'Moo';
requires 'Try::Catch';
requires 'Ouch';
requires 'namespace::clean';
requires 'strictures';
requires 'Math::GF';
requires 'Path::Tiny';

on test => sub {
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'Path::Tiny';
};
