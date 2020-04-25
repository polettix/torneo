package Game::Torneo::Model;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Scalar::Util 'blessed';
use Module::Runtime 'use_module';
use Game::Torneo::Model::Arrangement ();

has backend => (is => 'ro', required => 1);

around BUILDARGS => sub ($orig, $class, %args) {
   $args{backend} = use_module($args{backend}{class})->new($args{backend})
     if $args{backend} && ! blessed $args{backend};
   return $class->$orig(%args);
};

sub create ($self, %args) {
   return Game::Torneo::Model::Arrangement::create(%args);
}

sub create_and_save ($self, %args) {
   my $torneo = $self->create(%args);
   $self->save($torneo);
   return $torneo;
}

sub delete ($self, $torneo) {
   $self->backend->delete($torneo);
   return $self;
}

sub save_as_new ($self, $torneo) {
   $self->backend->create($torneo);
   return $self;
}

sub save ($self, $torneo) {
   return $self->save_as_new($torneo) unless defined $torneo->id;
   $self->backend->update($torneo);
   return $self;
}

sub load ($self, $id) { return $self->backend->retrieve($id) }

sub list ($self) { return $self->backend->search }

1;
