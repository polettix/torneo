package Game::Torneo::Model::Torneo;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util qw< args check_arrayref_of uuid >;
use Game::Torneo::Model::Score;
use Storable 'dclone';

sub _add_scores ($h1, $h2) {
   while (my ($id, $score) = each $h2->%*) {
      $h1->{$id} //= 0;
      $h1->{$id} += $score;
   }
   return $h1;
} ## end sub _add_scores

sub _hash_to_scores ($h) {
   return [
      reverse sort { $a->value <=> $b->value }
        map {
         Game::Torneo::Model::Score->new(
            participant => $_,
            value       => $h->{$_}
           )
        } keys $h->%*
   ];
} ## end sub _hash_to_scores ($h)

sub _scores_to_plainarray ($as) {
   return [map { $_->as_hash } $as->@*];
}

use namespace::clean;

has _participants =>
  (is => 'ro', init_arg => 'participants', required => 1);

has id => (is => 'rw', default => undef);

has rounds => (
   is       => 'ro',
   required => 1,
   isa      => sub {
      my $e = check_arrayref_of($_[0], 'Game::Torneo::Model::Round')
        or return;
      ouch 500, $e;
   },
);

sub participants_map ($self) { return $self->_participants->%* }

sub participant_for ($self, $id) {
   my $ps = $self->_participants;
   ouch 404, "participant $id not found" unless exists $ps->{$id};
   return $ps->{$id};
}

sub scores ($self) {
   my (%settled, %provisional);
   for my $round ($self->rounds->@*) {
      my $rs = $round->scores;
      _add_scores(\%settled,     $rs->{settled});
      _add_scores(\%provisional, $rs->{provisional});
   }
   my %check = (%settled, %provisional);    # grab all of them!
   for my $id (keys $self->_participants->%*) {
      $provisional{$id} //= 0;
      $settled{$id}     //= 0;
      delete $check{$id};
   }
   ouch 400, "unexpected players in torneo (@{[keys %check]})"
     if scalar keys %check;
   return {
      settled     => _hash_to_scores(\%settled),
      provisional => _hash_to_scores(\%provisional),
   };
} ## end sub scores ($self)

sub as_hash ($self) {
   my $scores = $self->scores;
   $_ = _scores_to_plainarray($_) for values $scores->%*;
   my $psh = $self->_participants;
   my %ps = map { $_ => $psh->{$_}->as_hash } keys $psh->%*;
   return {
      id           => $self->id,
      participants => \%ps,
      rounds       => [map { $_->as_hash } $self->rounds->@*],
      scores       => $scores,
   };
} ## end sub as_hash ($self)

1;
