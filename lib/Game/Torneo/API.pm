package Game::Torneo::API;
use 5.024;
use Mojo::Base 'Mojolicious', '-signatures';
use strictures 2;
use experimental qw< postderef >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Try::Catch;
use Scalar::Util 'blessed';

has model => sub {
   require Game::Torneo::Model;
   return Game::Torneo::Model->new(
      backend => {
         class => 'Game::Torneo::Model::BackEnd::JsonFile',
         repo  => '.',
      }
   );
};

has prefix => '';

sub startup ($self) {
   $self->secrets([$ENV{GATOR_SECRET} // 'whate-ver']);

   my $r = $self->routes;
   $r->get('/torneos')->to('torneo#list');
   $r->post('/torneos')->to('torneo#create');
   $r->get('/torneos/:tid')->to('torneo#retrieve');
   $r->get('/torneos/:tid/rounds/:rid')->to('torneo#retrieve_round');
   $r->get('/torneos/:tid/rounds/:rid/matches/:mid')
     ->to('torneo#retrieve_match');
   $r->put('/torneos/:tid/rounds/:rid/matches/:mid/scores')
     ->to('torneo#record_match_outcome');

   $self->hook(
      around_dispatch => sub ($next, $c) {
         try { $next->() }
         catch {
            die $_ unless blessed($_) && $_->isa('Ouch');
            my ($code, $message) = ($_->code, $_->message);
            $self->log->error("Ouch<$code>: $message");
            $c->render(
               status => $code,
               json   => {message => $message},
            );
         };
      }
   );

} ## end sub startup ($self)

sub generate_url ($self, @path) {
   return join '/', $self->prefix, @path;
}

1;
