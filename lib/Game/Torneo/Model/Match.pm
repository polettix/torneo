package Game::Torneo::Model::Match;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Util 'check_arrayref_of';
use Storable 'dclone';

# Handy local functions, not part of the API

sub _scores_are_equal ($h1, $h2) {
   while (my ($id, $score) = each $h1->%*) {
      return unless $h2->{$id} == $score;
   }
   return 1;
} ## end sub _scores_are_equal

use namespace::clean;

has id => (is => 'rw');
has participants => (is  => 'ro');
has judges => (is => 'ro', default => sub {return {}});

has score_from => (
   is      => 'rw',
   default => sub { return {} },
);

sub has_judges ($self) { return scalar(keys $self->judges->%*) > 0 }

sub is_judge ($self, $judge) {
   my $jh = $self->judges;
   return (!scalar keys $jh->%*) || (exists $jh->{$judge});
}

sub record_scores ($self, $judge, $scores) {
   $judge //= '';
   ouch 400, "$judge not a judge in match " . $self->id
     unless $self->is_judge($judge);

   my $participants = $self->participants;
   my %saved_score_for = map { $_ => 0 } keys $participants->%*;
   while (my ($id, $score) = each $scores->%*) {
      ouch 400, "spurious scores for unexpected ($id)"
         unless exists $participants->{$id};
      $saved_score_for{$id} = $score;
   }
   my $sf = $self->score_from;
   $sf->%* = () unless $self->has_judges;
   $sf->{$judge} = \%saved_score_for;
   return $self;
} ## end sub record_scores

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

   my $total_judges = scalar keys $self->judges->%*;
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
      id => $self->id,
      participants => [keys $self->participants->%*],
      #      judges => [keys $self->judges->%*],
      score_from => dclone($self->score_from),
   };
}

1;
