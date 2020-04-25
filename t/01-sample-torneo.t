use strict;
use experimental 'postderef';
use Test::More;
use Test::Exception;
use Game::Torneo::Model::Arrangement ();

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

my $torneo;
lives_ok {
   $torneo = Game::Torneo::Model::Arrangement::create(
      participants      => \@players,
      players_per_match => 3,
      premium           => 0,
   );
} ## end lives_ok
'creation of a torneo (non-premium)';

lives_ok {
   $torneo = Game::Torneo::Model::Arrangement::create(
      participants      => \@players,
      players_per_match => 3,
      premium           => 1,
   );
} ## end lives_ok
'creation of a torneo (premium)';

isa_ok $torneo, 'Game::Torneo::Model::Torneo';

is $torneo->id, undef, 'default torneo identifier';
$torneo->id('whatever');
is $torneo->id, 'whatever', 'updated torneo identifier';

is scalar($torneo->rounds->@*), 4, 'number of rounds';
is scalar($torneo->rounds->[0]->matches->@*), 3, 'matches in round';
is scalar(keys $torneo->rounds->[0]->matches->[0]->participants->%*), 3,
  'participants in match';

done_testing();
