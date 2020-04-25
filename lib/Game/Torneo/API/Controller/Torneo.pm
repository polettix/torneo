package Game::Torneo::API::Controller::Torneo;
use 5.024;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use strictures 2;
use experimental qw< postderef >;
no warnings qw< experimental::postderef experimental::signatures >;
use Ouch ':trytiny_var';
use Try::Catch;

sub model ($self) { return $self->app->model }
sub generate_url ($self, @args) { return $self->app->generate_url(@args) }

sub expand_torneo ($self, $t) {
   my $app    = $self->app;
   my $torneo = $t->as_hash;
   my $tid    = delete $torneo->{id};
   $t->{url} = $self->_url($tid);
   my (%round_for, %match_for);
   for my $round ($torneo->{rounds}->@*) {
      my $rid = delete $round->{id};
      my $rurl = $round->{url} = $self->_url($tid, $rid);
      $round_for{$rurl} = $round;
      for my $match ($round->{matches}->@*) {
         my $mid = delete $match->{id};
         my $murl = $match->{url} = $self->_url($tid, $rid, $mid);
         $match_for{$murl} = $match;
      }
   } ## end for my $round ($torneo->...)
   return {
      torneo    => $torneo,
      round_for => \%round_for,
      match_for => \%match_for,
   };
} ## end sub expand_torneo

sub list ($self) {
   my $app = $self->app;
   my @list = map { {id => $_, url => $app->generate_url(torneos => $_)} }
     $app->model->list;
   return $self->render(json => \@list);
} ## end sub list ($self)

sub _url ($self, $tid, $rid = undef, $mid = undef) {
   return $self->app->generate_url(torneos => $tid) unless defined $rid;
   return $self->app->generate_url(torneos => $tid, rounds => $rid)
     unless defined $mid;
   return $self->app->generate_url(
      torneos => $tid,
      rounds  => $rid,
      matches => $mid
   );
} ## end sub _url

sub _retrieve ($self, $tid, $rid = undef, $mid = undef) {
   my $torneo = $self->model->load($tid) or ouch 404, 'Not Found';
   my $expanded = $self->expand_torneo($self->model->load($tid));
   my $retval =
       !defined $rid ? $expanded->{torneo}
     : !defined $mid ? $expanded->{round_for}{$self->_url($tid, $rid)}
     :   $expanded->{match_for}{$self->_url($tid, $rid, $mid)};
   ouch 404, 'Not Found' unless defined $retval;
   return $retval;
} ## end sub _retrieve

sub retrieve ($self) {
   return $self->render(json => $self->_retrieve($self->param('tid')));
}

sub retrieve_round ($self) {
   my ($tid, $rid) = map { $self->param($_) } qw< tid rid >;
   return $self->render(json => $self->_retrieve($tid, $rid));
}

sub retrieve_match ($self) {
   my ($tid, $rid, $mid) = map { $self->param($_) } qw< tid rid mid >;
   return $self->render(json => $self->_retrieve($tid, $rid, $mid));
}

sub create ($self) {
   my $model  = $self->model;
   my $torneo = $model->create_and_save($self->req->json->%*);
   return $self->render(json => $self->expand_torneo($torneo)->{torneo});
}

sub set_status ($self)       { ... }
sub set_round_status ($self) { ... }
sub set_match_status ($self) { ... }

sub record_match_outcome ($self) {
   my ($tid, $rid, $mid) = map { $self->param($_) } qw< tid rid mid >;
   my $model  = $self->model;
   my $torneo = $model->load($tid);
   my $match  = $torneo->rounds->[$rid - 1]->matches->[$mid - 1];
   $match->record_scores(undef, $self->req->json);
   $model->save($torneo);
   return $self->render(json => $self->expand_torneo($torneo));
} ## end sub record_match_outcome ($self)

1;
