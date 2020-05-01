package Game::Torneo::Model::BackEnd::MojoDb;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Game::Torneo::Model::Torneo;
use Game::Torneo::Model::Util 'uuid';
use Module::Runtime 'use_module';
use Mojo::JSON qw< encode_json decode_json >;

sub _insert_returning_id ($db, $t, $v, $o = {}) {
   eval { $db->insert($t, $v, {$o->%*, returning => 'id'})->hash->{id} }
      || $db->insert($t, $v, $o)->last_insert_id;
}

sub _data_for ($driver) {
   state $migration_for = {
      postgresql => {
         class      => 'Mojo::Pg',
         init_db    => \&_init_db_pg,
         migrations => <<'END',

-- 1 up
create table if not exists torneo (
   id        serial primary key,
   metadata  text,
   secret    text,
   is_active boolean
);

create table if not exists participant (
   torneo      integer,
   id          text,
   is_premium  boolean,
   primary key (torneo, id)
);

create table if not exists round (
   torneo      integer,
   id          serial,
   matches_can_overlap boolean,
   primary key (torneo, id)
);

create table if not exists match (
   torneo      integer,
   round       integer,
   id          integer,
   metadata    text,
   secret      text,
   score_from  text,
   primary key (torneo, round, id)
);

create table if not exists match_participant (
   torneo      integer,
   round       integer,
   match       integer,
   participant text,
   primary key (torneo, round, match, participant)
);
 
-- 1 down
drop table if exists torneo;
drop table if exists participant;
drop table if exists round;
drop table if exists match;
drop table if exists match_participant;

END
      },
      sqlite => {
         class      => 'Mojo::SQLite',
         init_db    => \&_init_db_sqlite,
         migrations => <<'END',

-- 1 up
create table if not exists torneo (
   id        integer primary key,
   metadata  text,
   secret    text,
   is_active boolean
);

create table if not exists participant (
   torneo      integer,
   id          text,
   is_premium  boolean,
   primary key (torneo, id)
);

create table if not exists round (
   torneo      integer,
   id          integer,
   matches_can_overlap boolean,
   primary key (torneo, id)
);

create table if not exists match (
   torneo      integer,
   round       integer,
   id          integer,
   metadata    text,
   secret      text,
   score_from  text,
   primary key (torneo, round, id)
);

create table if not exists match_participant (
   torneo      integer,
   round       integer,
   match       integer,
   participant text,
   primary key (torneo, round, match, participant)
);
 
-- 1 down
drop table if exists torneo;
drop table if exists participant;
drop table if exists round;
drop table if exists match;
drop table if exists match_participant;

END
      },
   };
   $driver = lc($driver eq 'postgres' ? 'postgresql' : $driver);
   return $migration_for->{$driver};
} ## end sub _data_for ($driver)

sub _init_db_sqlite ($dsn) {
   require Mojo::SQLite;
   return Mojo::SQLite->new($dsn);
}

sub _init_db_pg ($dsn) {
   require Mojo::Pg;
   my $retval = eval {
      my $mpg = Mojo::Pg->new($dsn);
      $mpg->db;
      $mpg;
   };
   if (! $retval) {
   warn "\n\nhere\n\n";
      my ($prefix, $dbname) = $dsn =~ m{\A(postgres(?:ql)?://.*?)/(.*)};
      my $tmp = Mojo::Pg->new("$prefix/postgres");
      $tmp->db->query("CREATE DATABASE $dbname");
      $retval = Mojo::Pg->new($dsn);
   }
   return $retval;
}

use namespace::clean;

has dsn => (is => 'ro', default => '.');
has mdb => (is => 'lazy');

sub _build_mdb ($self) {
   my $dsn = $self->dsn;
   my ($driver) = $dsn =~ m{\A (.*?) : }mxs
     or ouch 400, "string <$dsn> is not a valid data source";
   my $driver_data = _data_for($driver)
     or ouch 400, "unsupported driver in data source <$dsn>";
   my $instance = $driver_data->{init_db}->($dsn);
   $instance->auto_migrate(1)->migrations->name('db')
     ->from_string($driver_data->{migrations});
   return $instance;
} ## end sub _build_mdb ($self)

sub create ($self, $torneo) {
   my $db = $self->mdb->db;

   # create torneo - this changes across db backends :(
   my $tid = _insert_returning_id($db,
      torneo => {
            secret => $torneo->secret,
            metadata => encode_json({meta => $torneo->metadata}),
            is_active => 1,
      }
   );
   $torneo->id($tid);

   # create participants
   for my $participant (values {$torneo->participants_map}->%*) {
      $db->insert(
         participant => {
            torneo => $tid,
            id     => $participant->id,
            is_premium => ($participant->is_premium ? 1 : 0),
         },
      );
   }

   # create rounds & matches
   for my $round ($torneo->rounds->@*) {
      my $rid = $round->id;
      $db->insert(
         round => {
            torneo => $tid,
            id     => $rid,
            matches_can_overlap => ($round->matches_can_overlap ? 1 : 0),
         },
      );
      for my $match ($round->matches->@*) {
         my $mid = $match->id;
         $db->insert(
            match => {
               torneo => $tid,
               round  => $rid,
               id     => $mid,
               score_from => encode_json($match->score_from),
               metadata => encode_json({meta => $match->metadata}),
               secret => $match->secret,
            },
         );

         for my $participant ($match->participants->@*) {
            $db->insert(
               match_participant => {
                  torneo => $tid,
                  round  => $rid,
                  match  => $mid,
                  participant => $participant,
               },
            );
         }
      }
   }

   return $self;
}

sub retrieve ($self, $tid) {
   my $db = $self->mdb->db;

   # top-level hash
   my $hash = $db->select(torneo => undef, {id => $tid, is_active => 1})->hash
      or ouch 404, 'Not Found';
   $hash->{metadata} = decode_json($hash->{metadata})->{meta};

   # add participants
   $hash->{participants} = \my %participants;
   $db->select(participant => undef, {torneo => $tid})->hashes
      ->each(
         sub ($p, $i) {
            $participants{$p->{id}} = $p;
         }
      );

   # load everything else
   $hash->{rounds} = \my @rounds;
   $db->select(round => undef, {torneo => $tid})->hashes->each(
      sub ($r, $ir) {
         my $rid = $r->{id};
         $rounds[$rid - 1] = $r;
         $r->{matches} = \my @matches;
         $db->select(match => undef, {torneo => $tid, round => $rid})
            ->hashes
            ->each(
               sub ($m, $im) {
                  my $mid = $m->{id};
                  $matches[$mid - 1] = $m;
                  $m->{$_} = decode_json($m->{$_})
                     for qw< metadata score_from >;
                  $m->{metadata} = $m->{metadata}{meta};
                  $m->{participants} = \my @ps;
                  $db->select(match_participant => ['participant'],
                     {torneo => $tid, round => $rid, match => $mid}
                  )->hashes
                  ->each(sub ($mp, $imp) { push @ps, $mp->{participant} });
               }
            );
      }
   );
   use Data::Dumper;
   $Data::Dumper::Indent = 1;
   #say {*STDERR} Dumper $hash;
#   exit 1;
   return Game::Torneo::Model::Torneo->from_hash($hash);
}

sub update ($self, $torneo) {
   my $db = $self->mdb->db;
   my $tid = $torneo->id;

   # check presence and activity of torneo
   $db->select(torneo => undef, {id => $tid, is_active => 1})
      or ouch 404, 'Not Found'; # possibly not needed

   for my $round ($torneo->rounds->@*) {
      my $rid = $round->id;
      for my $match ($round->matches->@*) {
         next unless $match->scores_were_touched;
         my $sf = encode_json($match->score_from);
         $db->update(match => {score_from => $sf},
            {torneo => $tid, round => $rid, id => $match->id});
         $match->scores_were_touched(0); # reset flag
      }
   }
   return;
}

sub delete ($self, $torneo) {
   $self->mdb->db->update(torneo => {is_active => 0}, {id => $torneo->id});
   return;
}

sub search ($self, %opts) {
   return $self->mdb->db->select(torneo => ['id']) ->arrays
      ->map(sub {$_->[0]})->each;
}

1;
