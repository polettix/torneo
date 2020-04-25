package Game::Torneo::Model::BackEnd::StorableFile;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Storable ();
use Path::Tiny 'path';

sub _new_id { sprintf '%s-%03d', time(), rand(1000) }

use namespace::clean;

sub _filename_from_id ($self, $id) {
   return path($self->repo)->child($self->prefix . $id)->stringify;
}

sub _id_from_filename ($self, $filename) {
   my $name = path($filename)->basename;
   my $prefix = $self->prefix;
   my $prefix_length = length $prefix;
   return $name unless $prefix_length > 0;
   return undef unless index($name, $prefix) == 0;
   return substr $name, $prefix_length ;
}

has repo => (is => 'ro', default => '.');
has prefix => (is => 'rw', default => 'torneo-');

sub create ($self, $torneo) {
   $torneo->id(_new_id());
   $self->update($torneo);
}

sub retrieve ($self, $id) {
   my $filename = $self->_filename_from_id($id);
   ouch 404, 'Not Found' unless -e $filename;
   my $torneo = Storable::retrieve($filename);
   $torneo->id($id);
   return $torneo;
}

sub update ($s, $t) { Storable::nstore($t, $s->_filename_from_id($t->id)) }

sub delete ($s, $t) { unlink $s->_filename_from_id($t->id) }

sub search ($self, %opts) {
   my $repo = path($self->repo);
   map {
      my $id = $self->_id_from_filename($_);
      defined $id ? $id : ();
   } $repo->children;
}

1;
