package Game::Torneo::API;
use 5.024;
use Mojo::Base 'Mojolicious', '-signatures';
use strictures 2;
use experimental qw< postderef >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Try::Catch;
use Scalar::Util 'blessed';
use Game::Torneo::Model;

has 'config';
has 'model';
has 'prefix' => '';

sub startup ($self) {
   my $config = $Game::Torneo::API::config // {};
   $self->config($config);
   $self->model(Game::Torneo::Model->new(backend => $config->{backend}));

   my $prefix = $config->{prefix} // '';
   if (length $prefix) {
      ($prefix = '/' . $prefix) =~ s{\A /+}{/}mxs;
      $prefix =~ s{/+ \z}{}mxs;
      $self->prefix($prefix);
   }

#   $self->hook(
#      before_dispatch => sub ($c) {
#         my $url = $c->req->url;
#         $self->log->debug("requested url is $url");
#         $url->path($prefix . $url->path->to_string);
#         $self->log->debug("now $url");
#      }
#   ) if length $prefix;

   $self->secrets($config->{secrets} // ['whate-ver']);

   my $r = $self->routes;
   $r->get(
      '/' => sub ($c) {
         $c->stash('prefix' => $prefix);
         $c->render(template => 'app');
      }
   );

   $r->get('/torneos')->to('torneo#list');
   $r->post('/torneos')->to('torneo#create');

   $r->get('/torneos/:tid')->to('torneo#retrieve');
   $r->delete('/torneos/:etid')->to('torneo#delete');

   $r->get('/torneos/:tid/rounds/:rid')->to('torneo#retrieve_round');

   $r->get('/torneos/:tid/rounds/:rid/matches/:mid')
     ->to('torneo#retrieve_match');
   $r->put('/torneos/:tid/rounds/:rid/matches/:emid/scores')
     ->to('torneo#record_match_outcome');
   $r->delete('/torneos/:tid/rounds/:rid/matches/:emid/scores')
     ->to('torneo#clear_match_outcome');

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

   $self->log->debug("Started");
} ## end sub startup ($self)

sub generate_url ($self, @path) {
   return join '/', $self->prefix, @path;
}

1;
