package Game::Torneo::Model::BackEnd::JsonFile;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use JSON::PP qw< encode_json decode_json >;
use Path::Tiny 'path';
use Game::Torneo::Model::Torneo;

sub _new_id { sprintf '%s-%03d', time(), rand(1000) }

use namespace::clean;

sub _filename_from_id ($self, $id) {
   return path($self->repo)->child($self->prefix . $id. '.json');
}

sub _id_from_filename ($self, $filename) {
   my $name = path($filename)->basename;
   return undef unless $name =~ s{\.json\z}{}mxs;
   my $prefix = $self->prefix;
   my $prefix_length = length $prefix;
   return $name unless $prefix_length > 0;
   return undef unless index($name, $prefix) == 0;
   return substr $name, $prefix_length;
}

has repo => (is => 'ro', default => '.');
has prefix => (is => 'rw', default => 'torneo-');

sub create ($self, $torneo) {
   $torneo->id(_new_id());
   $self->update($torneo);
}

sub retrieve ($self, $id) {
   my $filename = $self->_filename_from_id($id);
   ouch 404, 'Not Found' unless $filename->exists;
   my $hash = decode_json($filename->slurp_utf8);
   my $torneo = Game::Torneo::Model::Torneo->from_hash($hash);
   $torneo->id($id);
   return $torneo;
}

sub update ($self, $torneo) {
   my $filename = $self->_filename_from_id($torneo->id);
   my $hash = $torneo->as_hash;
   delete $hash->{scores};
   $filename->spew_utf8(encode_json($hash));
   return $self;
}

sub delete ($s, $t) {
   my $filename = $s->_filename_from_id($t->id);
   $filename->move($filename . '.archived');
}

sub search ($self, %opts) {
   my $repo = path($self->repo);
   map {
      my $id = $self->_id_from_filename($_);
      defined $id ? $id : ();
   } $repo->children;
}

1;
