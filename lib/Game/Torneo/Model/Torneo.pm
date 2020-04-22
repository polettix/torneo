package Game::Torneo::Model::Torneo;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util qw< check_arrayref_of uuid >;

sub _add_scores ($h1, $h2) {
   while (my ($id, $score) = each $h2->%*) {
      $h1->{$id} //= 0;
      $h1->{$id} += $score;
   }
   return $h1;
}

use namespace::clean;

with 'Game::Torneo::Model::RoleParticipants';

has id => (is => 'rw', default => undef);

has rounds => (
   is  => 'ro',
   required => 1,
   isa => sub {
      my $e = check_arrayref_of($_[0], 'Game::Torneo::Model::Round')
         or return;
      ouch 500, $e;
   },
);

sub scores ($self) {
   my (%settled, %provisional);
   for my $round ($self->rounds->@*) {
      my $rs = $round->scores;
      _add_scores(\%settled, $rs->{settled});
      _add_scores(\%provisional, $rs->{provisional});
   }
   my %check = (%settled, %provisional); # grab all of them!
   for my $participant ($self->participants->@*) {
      my $id = $participant->id;
      $provisional{$id} //= 0;
      $settled{$id} //= 0;
      delete $check{$id};
   }
   ouch 'unexpected players in torneo' if scalar keys %check;
   return {
      settled => \%settled,
      provisional => \%provisional,
   };
}

1;
