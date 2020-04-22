use strict;
use experimental 'postderef';
use Test::More;
use Test::Exception;
use Game::Torneo::Model ();
use Path::Tiny 'path';

my @players = (
   {id => 1, is_premium => 0, data => 'Ada'},
   {id => 2, is_premium => 1, data => 'Biagio'},
   {id => 3, is_premium => 1, data => 'Carla'},
   {id => 4, is_premium => 0, data => 'Davide'},
   {id => 5, is_premium => 0, data => 'Emma'},
   {id => 6, is_premium => 1, data => 'Fulvio'},
   {id => 7, is_premium => 0, data => 'Giada'},
   {id => 8, is_premium => 1, data => 'Ivo'},
   {id => 9, is_premium => 1, data => 'Laura'},
);

my ($model, $torneo);
lives_ok {
   $model = Game::Torneo::Model->new(
      backend => {
         class => 'Game::Torneo::Model::BackEnd::StorableMemory',
      },
   );
   $torneo = $model->create(
      participants      => \@players,
      players_per_match => 3,
      premium           => 1,
   );
   $model->save($torneo);
   $torneo = $model->load($torneo->id);
} 'creation of Model and Torneo objects, save and reload';

my $round1 = $torneo->rounds->[0];
isa_ok $round1, 'Game::Torneo::Model::Round';

my $match1 = $round1->matches->[0];
isa_ok $match1, 'Game::Torneo::Model::Match';

my @participants = map {$_->id} $match1->participants->@*;
is scalar(@participants), 3, 'number of participants';

my %score_for;
@score_for{@participants} = qw< 2 4 6 >;
$match1->record_scores(somebody => \%score_for);

my $scores;
lives_ok { $scores = $torneo->scores } 'get scores';
is scalar($scores->{settled}->@*), 9, 'settled scores';
is $scores->{settled}->[0]->value, 6, 'score for first player';
is $scores->{settled}->[1]->value, 4, 'score for second player';
is $scores->{settled}->[2]->value, 2, 'score for third player';
is $scores->{settled}->[3]->value, 0, 'score for fourth player';
is $scores->{settled}->[-1]->value, 0, 'score for last player';

lives_ok { $model->save($torneo) } 'save the whole torneo';

lives_ok { $torneo = $model->load($torneo->id) } 'reload it';
lives_ok { $scores = $torneo->scores } 'get scores';
is scalar($scores->{settled}->@*), 9, 'settled scores';
is $scores->{settled}->[0]->value, 6, 'score for first player';
is $scores->{settled}->[1]->value, 4, 'score for second player';
is $scores->{settled}->[2]->value, 2, 'score for third player';
is $scores->{settled}->[3]->value, 0, 'score for fourth player';
is $scores->{settled}->[-1]->value, 0, 'score for last player';


done_testing();
