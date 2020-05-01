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
requires 'DBI';
requires 'Mojo::SQLite';
requires 'Mojo::Pg';

on test => sub {
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'Path::Tiny';
};
