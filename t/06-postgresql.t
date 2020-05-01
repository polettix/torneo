use strict;
use experimental 'postderef';
use Test::More;
use Test::Exception;
use Game::Torneo::Model ();
use Path::Tiny 'path';

plan skip_all => "POSTGRESQL_DATABASE_URL environment variable not set"
  unless defined $ENV{POSTGRESQL_DATABASE_URL};

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

my $dbfile = path(__FILE__ . '.sqlite');
$dbfile->remove if $dbfile->exists;

my $model;
lives_ok {
   $model = Game::Torneo::Model->new(
      backend => {
         class => 'Game::Torneo::Model::BackEnd::MojoDb',
         dsn => $ENV{POSTGRESQL_DATABASE_URL},
      },
   );
   my $db = $model->backend->mdb->db;
} 'creation of Model object';

my $torneo;
lives_ok {
   $torneo = $model->create(
      participants      => \@players,
      players_per_match => 3,
      premium           => 1,
      metadata          => {title => 'Wow a Torneo!'},
   );
} ## end lives_ok
'creation of a torneo (premium)';
isa_ok $torneo, 'Game::Torneo::Model::Torneo';
is $torneo->id, undef, 'default identifier is undefined';

lives_ok { $model->save($torneo) } 'save the whole torneo';

my $id = $torneo->id;
ok defined($id), 'saved torneo got an id';

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
