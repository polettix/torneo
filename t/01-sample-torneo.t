use strict;
use experimental 'postderef';
use Test::More;
use Test::Exception;
use Game::Torneo::Model::Arrangement ();

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
is scalar($torneo->rounds->[0]->matches->[0]->participants->@*), 3,
  'participants in match';

done_testing();
