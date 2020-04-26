package Game::Torneo::Model::Participant;
use 5.024;
use Moo;
use strictures 2;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Storable 'dclone';
use namespace::clean;

has id => (is => 'rw');
has is_premium => (is => 'rw', default => 0);

around BUILDARGS => sub ($orig, $class, @args) {
   my %args = @args && ref $args[0] ? $args[0]->%* : @args;
   $args{is_premium} = ($args{premium} || $args{is_premium}) ? 1 : 0;
   return $class->$orig(%args);
};

sub as_hash ($self) {
   return {
      id => $self->id,
      is_premium => $self->is_premium,
   };
}

sub from_hash ($class, $hash) { $class->new($hash->%*) }

1;
