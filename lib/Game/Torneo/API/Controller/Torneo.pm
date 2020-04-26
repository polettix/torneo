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
      $round_for{$rid} = $round;
      for my $match ($round->{matches}->@*) {
         delete $match->{judges};
         my $sf = delete $match->{score_from};
         $match->{scores} = $sf->{''} if exists $sf->{''};
         my $mid = delete $match->{id};
         my $murl = $match->{url}{read} = $self->_url($tid, $rid, $mid);
         $match_for{$rid}{$mid} = $match;
         my $ms = delete $match->{secret};
         $match->{url}{scores} = $self->_url($tid, $rid, "$mid-$ms", 'scores')
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

sub _retrieve ($self, $etid, $rid = undef, $emid = undef) {
   my ($tid, $secret) = $etid =~ m{\A (\w+) (?: - (\w+))? \z}mxs
     or ouch 400, "invalid torneo identifier <$etid>";
   my $torneo = $self->model->load($tid) or ouch 404, 'Not Found';

   my $expanded = $self->expand_torneo($torneo, $secret);
   return $expanded->{torneo} unless defined $rid;

   if (! defined $emid) {
      ouch 404, 'Not Found' unless exists $expanded->{round_for}{$rid};
      return $expanded->{round_for}{$rid};
   }

   my ($mid, $msecret) = $emid =~ m{\A (\w+) (?: - (\w+))? \z}mxs
      or ouch 400, "invalid match identifier <$emid>";
   ouch 404, 'Not Found'
      unless exists $expanded->{match_for}{$rid}{$mid};

   # "refresh" expansion if needed
   my $match = $torneo->rounds->[$rid]->matches->[$mid];
   $expanded = $self->expand_torneo($torneo, $torneo->secret)
      if defined($msecret) && $msecret eq $match->secret
         && !(defined($secret) && $secret eq $torneo->secret);

   # now we can return
   return $expanded->{match_for}{$rid}{$mid};
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

sub delete ($self) {
   my $etid = $self->param('etid');
   my ($tid, $secret) = $etid =~ m{\A (\w+) - (\w+) \z}mxs
     or ouch 400, "invalid torneo identifier for deletion <$etid>";
   my $model = $self->model;
   my $torneo;
   try {
      $torneo = $model->load($tid);
      ouch 403, 'sorry, the provided secret deos not match mine'
         unless $secret eq $torneo->secret;
      $model->delete($torneo);
   }
   catch {
      die $_ unless kiss 404; # ignore "Not Found" :)
   };
   return $self->render(status => 204, data => '');
}

sub set_status ($self)       { ... }
sub set_round_status ($self) { ... }
sub set_match_status ($self) { ... }

sub _record_match_scores ($self, $scores) {
   my ($tid, $rid, $emid) = map { $self->param($_) } qw< tid rid emid >;
   my ($mid, $secret) = $emid =~ m{\A (\w+) - (\w+) \z}mxs
     or ouch 400, "invalid match identifier for setting scores <$emid>";
   my $model  = $self->model;
   my $torneo = $model->load($tid);
   my $match  = $torneo->rounds->[$rid - 1]->matches->[$mid - 1];
   ouch 403, 'sorry, the provided secret does not match mine'
      unless $secret eq $match->secret;
   if ($scores) {
      $match->record_scores(undef, $scores);
   }
   else {
      $match->clear_scores(undef);
   }
   $model->save($torneo);
   my $etid = $tid . '-' . $torneo->secret;
   return $self->render(json => $self->_retrieve($etid, $rid, $mid));
}

sub record_match_outcome ($self) {
   $self->_record_match_scores($self->req->json);
} ## end sub record_match_outcome ($self)

sub clear_match_outcome ($self) {
   $self->_record_match_scores(undef);
}

1;
