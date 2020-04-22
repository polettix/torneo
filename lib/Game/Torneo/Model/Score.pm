package Game::Torneo::Model::Score;
use 5.024;
use Moo;
use strictures 2;
use namespace::clean;

has participant => (is => 'ro', required => 1);
has value => (is => 'rw', default => 0);

1;
