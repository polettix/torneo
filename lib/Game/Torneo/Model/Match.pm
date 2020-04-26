package Game::Torneo::Model::Match;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util qw< args check_arrayref_of >;
use Storable 'dclone';

# Handy local functions, not part of the API

sub _scores_are_equal ($h1, $h2) {
   while (my ($id, $score) = each $h1->%*) {
      return unless $h2->{$id} == $score;
   }
   return 1;
} ## end sub _scores_are_equal

use namespace::clean;

with 'Game::Torneo::Model::RoleSecretHolder';
has id           => (is => 'rw');
has participants => (is => 'ro');
has judges       => (is => 'ro', default => sub { return [] });

has score_from => (
   is      => 'rw',
   default => sub { return {} },
);

sub has_judges ($self) { return scalar($self->judges->@*) > 0 }

sub is_judge ($self, $judge) {
   my $judges = $self->judges;
   return 1 if scalar($judges->@*) == 0;    # no judge, anybody is judge
   return grep { $_ eq $judge } $judges->@*;
}

sub record_scores ($self, $judge, $scores) {
   $judge //= '';
   ouch 400, "$judge not a judge in match " . $self->id
     unless $self->is_judge($judge);

   my %saved_score_for = map { $_ => 0 } $self->participants->@*;
   while (my ($id, $score) = each $scores->%*) {
      ouch 400, "unexpected participant in match ($id)"
        unless exists $saved_score_for{$id};
      $saved_score_for{$id} = $score;
   }
   my $sf = $self->score_from;
   $sf->%* = () unless $self->has_judges;
   $sf->{$judge} = \%saved_score_for;
   return $self;
} ## end sub record_scores

sub clear_scores ($self, $judge) {
   $judge //= '';
   ouch 400, "$judge not a judge in match " . $self->id
     unless $self->is_judge($judge);
   my $sf = $self->score_from;
   if ($self->has_judges) {
      delete $sf->{$judge};
   }
   else {
      $sf->%* = ();
   }
   return $self;
}

sub scores ($self) {
   my %tally;

 JUDGE:
   while (my ($judge, $scores) = each $self->score_from->%*) {
      while (my ($pj, $pas) = each %tally) {
         if (_scores_are_equal($scores, $pas->{scores})) {    # agreement
            $pas->{n}++;
            next JUDGE;
         }
      } ## end while (my ($pj, $pas) = each...)

      # new one here
      $tally{$judge} = {
         scores => {$scores->%*},
         n      => 1,
      };
   } ## end JUDGE: while (my ($judge, $scores...))
   my @alternatives = reverse sort { $a->{n} <=> $b->{n} } values %tally;

   my $total_judges = scalar $self->judges->@*;
   my $quorum       = int($total_judges / 2) + 1;
   my %retval       = (
      quorum => $quorum,
      all    => \@alternatives,
   );
   $retval{status} =
       @alternatives == 0                        ? 'unknown'
     : $alternatives[0]{n} >= $quorum            ? 'settled'
     : @alternatives == 1                        ? 'provisional'
     : $alternatives[0]{n} > $alternatives[1]{n} ? 'challenged'
     :                                             'disputed';
   $retval{best} = $alternatives[0]
     if @alternatives && $retval{status} ne 'disputed';
   return \%retval;
} ## end sub scores ($self)

sub as_hash ($self) {
   return {
      id           => $self->id,
      participants => dclone($self->participants),
      judges       => dclone($self->judges),
      score_from   => dclone($self->score_from),
      secret       => $self->secret,
   };
} ## end sub as_hash ($self)

sub from_hash ($class, $hash) {
   my %args;
   $args{id} = $hash->{id};
   $args{participants} = dclone($hash->{participants});
   $args{score_from} = dclone($hash->{score_from});
   $args{secret} = $hash->{secret} if exists $hash->{secret};
   return $class->new(%args);
} ## end sub from_hash

1;
