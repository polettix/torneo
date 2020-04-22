package Game::Torneo::Model::Participant;
use 5.024;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Moo;
use strictures 2;
use namespace::clean;

has id => (is => 'rw');
has is_premium => (is => 'rw', default => 0);
has data => (is => 'rw');

1;
