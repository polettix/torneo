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
} ## end lives_ok
'creation of Model and Torneo objects, save and reload';

my $torneo_hash = $torneo->as_hash;
isa_ok $torneo_hash, 'HASH';

for my $key (qw< participants rounds secret >) {
   ok exists $torneo_hash->{$key}, "hash has $key";
}

my $torneo_reconstructed;
lives_ok {
   $torneo_reconstructed =
     Game::Torneo::Model::Torneo->from_hash($torneo_hash);
}
'reconstruction from hash';

my $torneo_reconstructed_hash = $torneo_reconstructed->as_hash;

delete $_->{scores} for $torneo_reconstructed_hash, $torneo_hash;

is_deeply $torneo_reconstructed_hash, $torneo_hash, 'first and second hashifications match';

done_testing;
