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

with 'Game::Torneo::Model::RoleParticipants';
has _participants => (is => 'ro');

has id => (is => 'rw');

has judges => (is => 'ro', default => sub {[]});
has _judges => (is => 'ro');

has score_from => (
   is      => 'rw',
   default => sub { return {} },
);

around BUILDARGS => sub ($orig, $class, @args) {
   my %args = (@args > 0 && ref $args[0]) ? $args[0]->%* : @_;
   for my $key (qw< participants judges >) {
      my $aref = $args{$key} //= [];
      $args{'_' . $key} = {map { $_->id => 1 } $aref->@*};
   }
   return $class->$orig(\%args);
};

sub has_judges ($self) { return scalar($self->judges->@*) > 0 }

sub is_judge ($self, $judge) {
   my $jh = $self->_judges;
   return (!scalar keys $jh->%*) || (exists $jh->{$judge});
}

sub record_scores ($self, $judge, $scores) {
   $judge //= '';
   ouch 400, "$judge not a judge in match " . $self->id
     unless $self->is_judge($judge);

   my %input_score_for = $scores->%*;
   my %saved_score_for;
   for my $participant ($self->participants->@*) {
      $saved_score_for{$participant->id} =
        exists $input_score_for{$participant->id}
        ? delete $input_score_for{$participant->id}
        : 0;
   } ## end for my $participant ($self...)
   if (my @intruders = keys %input_score_for) {
      ouch 400, "spurious scores for unexpected (@intruders)";
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
      id => $self->id,
      participants => [map {$_->id} $self->participants->@*],
      judges => [map {$_->id} $self->judges->@*],
      score_from => dclone($self->score_from),
   };
}

1;
