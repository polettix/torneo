package Game::Torneo::Model::RoleSecretHolder;
use 5.024;
use Moo::Role;
use strictures 2;
use Game::Torneo::Model::Util 'uuid';
use namespace::clean;

has secret => (is  => 'ro', lazy => 1, default => sub { uuid() });

1;
