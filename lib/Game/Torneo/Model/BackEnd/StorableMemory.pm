package Game::Torneo::Model::BackEnd::StorableMemory;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Storable 'dclone';
use Path::Tiny 'path';

use namespace::clean;

has repo => (is => 'ro', default => sub { return [] });

sub create ($self, $torneo) {
   my $repo = $self->repo;
   $torneo->id(scalar $repo->@*);
   push $self->repo->@*, dclone($torneo);
   return;
}

sub retrieve ($self, $id) {
   my $repo = $self->repo;
   ouch 404, 'Not Found'
     if ($id > $repo->@* - 1) || (! defined $repo->[$id]);
   my $torneo = dclone($repo->[$id]);
   $torneo->id($id);
   return $torneo;
}

sub update ($s, $t) { $s->repo->[$t->id] = $t; return }

sub delete ($s, $t) { $s->repo->[$t->id] = undef }

sub search ($self, %opts) {
   my $repo = $self->repo;
   return unless $repo->@*;
   return 0 .. $#$repo;
}

1;
