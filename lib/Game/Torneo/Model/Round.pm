package Game::Torneo::Model::Round;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util 'check_arrayref_of';
use Game::Torneo::Model::Match;
use namespace::clean;

has id => (is => 'rw');

has matches => (
   is  => 'rw',
   isa => sub {
      my $e = check_arrayref_of($_[0], 'Game::Torneo::Model::Match')
        or return;
      ouch 500, $e;
   },
);

has matches_can_overlap => (is => 'rw', default => 0);

sub scores ($self) {
   my (%settled, %provisional);
   my $matches_can_overlap = $self->matches_can_overlap;
   for my $match ($self->matches->@*) {
      my $ms     = $match->scores;
      my $status = $ms->{status};
      next unless {settled => 1, provisional => 1}->{$status};
      while (my ($id, $score) = each $ms->{best}{scores}->%*) {
         ouch "player $id overlap"
           if exists $provisional{$id} && !$matches_can_overlap;
         $provisional{$id} //= 0;
         $provisional{$id} += $score;
         next if $status eq 'provisional';    # don't count in settled
         $settled{$id} //= 0;
         $settled{$id} += $score;
      } ## end while (my ($id, $score) =...)
   } ## end for my $match ($self->matches...)
   return {
      settled     => \%settled,
      provisional => \%provisional,
   };
} ## end sub scores ($self)

sub match_for ($self, $mid) {
   # inefficient but correct
   for my $match ($self->matches->@*) {
      return $match if $match->id eq $mid;
   }
   ouch 404, 'Match not found';
}

sub as_hash ($self) {
   return {
      id                  => $self->id,
      matches             => [map { $_->as_hash } $self->matches->@*],
      matches_can_overlap => $self->matches_can_overlap,
   };
} ## end sub as_hash ($self)

sub from_hash ($class, $hash) {
   my @matches = map { Game::Torneo::Model::Match->from_hash($_); }
     $hash->{matches}->@*;
   return $class->new(
      id                  => $hash->{id},
      matches             => \@matches,
      matches_can_overlap => $hash->{matches_can_overlap}
   );
} ## end sub from_hash

1;
