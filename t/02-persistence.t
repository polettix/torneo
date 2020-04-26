use strict;
use experimental 'postderef';
use Test::More;
use Test::Exception;
use Game::Torneo::Model ();
use Path::Tiny 'path';

my @players = (
   {is_premium => 0, id => 'Ada'},
   {is_premium => 1, id => 'Biagio'},
   {is_premium => 1, id => 'Carla'},
   {is_premium => 0, id => 'Davide'},
   {is_premium => 0, id => 'Emma'},
   {is_premium => 1, id => 'Fulvio'},
   {is_premium => 0, id => 'Giada'},
   {is_premium => 1, id => 'Ivo'},
   {is_premium => 1, id => 'Laura'},
);

my $repo = path(__FILE__ . '.repo');
$repo->remove_tree if $repo->exists;
$repo->mkpath;

my $model;
lives_ok {
   $model = Game::Torneo::Model->new(
      backend => {
         class => 'Game::Torneo::Model::BackEnd::JsonFile',
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

$torneo->id(9);
$model->save($torneo);

done_testing();
