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

sub expand_torneo ($self, $t, $secret = '') {
   my $app    = $self->app;
   my $torneo = $t->as_hash;

   my $tid = delete $torneo->{id};
   $torneo->{url}{read} = $self->_url($tid);

   my $ts  = delete $torneo->{secret};
   my $keep_secrets = defined $secret && $secret eq $ts;
   $torneo->{url}{write} = $self->_url("$tid-$ts") if $keep_secrets;

   my (%round_for, %match_for);
   for my $round ($torneo->{rounds}->@*) {
      my $rid = delete $round->{id};
      my $rurl = $round->{url} = $self->_url($tid, $rid);
      $round_for{$rurl} = $round;
      for my $match ($round->{matches}->@*) {
         delete $match->{judges};
         my $sf = delete $match->{score_from};
         $match->{scores} = $sf->{''} if exists $sf->{''};
         my $mid = delete $match->{id};
         my $murl = $match->{url}{read} = $self->_url($tid, $rid, $mid);
         $match_for{$murl} = $match;
         my $ms = delete $match->{secret};
         $match->{url}{put_scores} = $self->_url($tid, $rid, "$mid-$ms", 'scores')
            if $keep_secrets;
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

sub _url ($self, $tid, $rid = undef, $mid = undef, @rest) {
   return $self->app->generate_url(torneos => $tid) unless defined $rid;
   return $self->app->generate_url(torneos => $tid, rounds => $rid)
     unless defined $mid;
   return $self->app->generate_url(
      torneos => $tid,
      rounds  => $rid,
      matches => $mid,
      @rest,
   );
} ## end sub _url

sub _retrieve ($self, $etid, $rid = undef, $mid = undef) {
   my ($tid, $secret) = $etid =~ m{\A (\w+) (?: - (\w+))? \z}mxs
     or ouch 400, "invalid torneo identifier <$etid>";
   my $torneo = $self->model->load($tid) or ouch 404, 'Not Found';
   my $expanded = $self->expand_torneo($torneo, $secret);
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
   my $as_hash = $self->expand_torneo($torneo, $torneo->secret)->{torneo};
   return $self->render(json => $as_hash);
}

sub set_status ($self)       { ... }
sub set_round_status ($self) { ... }
sub set_match_status ($self) { ... }

sub record_match_outcome ($self) {
   my ($tid, $rid, $emid) = map { $self->param($_) } qw< tid rid mid >;
   my ($mid, $secret) = $emid =~ m{\A (\w+) - (\w+) \z}mxs
     or ouch 400, "invalid match identifier for setting scores <$emid>";
   my $model  = $self->model;
   my $torneo = $model->load($tid);
   my $match  = $torneo->rounds->[$rid - 1]->matches->[$mid - 1];
   ouch 403, 'sorry, the provided secret does not match mine'
      unless $secret eq $match->secret;
   $match->record_scores(undef, $self->req->json);
   $model->save($torneo);
   my $etid = $tid . '-' . $torneo->secret;
   return $self->render(json => $self->_retrieve($etid, $rid, $mid));
} ## end sub record_match_outcome ($self)

1;
