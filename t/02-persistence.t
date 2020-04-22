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

my $repo = path(__FILE__ . '.repo');
$repo->remove_tree if $repo->exists;
$repo->mkpath;

my $model;
lives_ok {
   $model = Game::Torneo::Model->new(
      backend => {
         class => 'Game::Torneo::Model::BackEnd::StorableFile',
         repo => $repo,
         prefix => 'test-',
      },
   );
} 'creation of Model object';

my $torneo;
lives_ok {
   $torneo = $model->create(
      participants      => \@players,
      players_per_match => 3,
      premium           => 1,
   );
} ## end lives_ok
'creation of a torneo (premium)';
isa_ok $torneo, 'Game::Torneo::Model::Torneo';
is $torneo->id, undef, 'default identifier is undefined';

lives_ok { $model->save($torneo) } 'save the whole torneo';

my $id = $torneo->id;
$torneo = undef;
lives_ok {
   $torneo = $model->load($id);
} 'retrieve the torneo';

isa_ok $torneo, 'Game::Torneo::Model::Torneo';
ok defined($torneo->id), 'saved/loaded torneo has an id';
diag 'Generated id: ' . $torneo->id;

is scalar($torneo->rounds->@*), 4, 'number of rounds';
is scalar($torneo->rounds->[0]->matches->@*), 3, 'matches in round';
is scalar($torneo->rounds->[0]->matches->[0]->participants->@*), 3,
  'participants in match';

done_testing();
