package Game::Torneo::Model::RoleParticipants;
use 5.024;
use Moo::Role;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util 'check_arrayref_of';
use namespace::clean;

has participants => (
   is => 'rw',
   isa => sub {
      my $e = check_arrayref_of($_[0], 'Game::Torneo::Model::Participant')
         or return;
      ouch 500, $e;
   },
);

sub participants_as_array ($self) {
   return [map {$_->as_hash} $self->participants->@*]; 
}

return 1;
