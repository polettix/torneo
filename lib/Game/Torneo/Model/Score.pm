package Game::Torneo::Model::Score;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use namespace::clean;

has participant => (is => 'ro', required => 1);
has value => (is => 'rw', default => 0);

sub as_hash ($self) {
   return {
      participant => $self->participant,
      value => $self->value,
   };
}

1;
