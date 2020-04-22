package Game::Torneo::Model::Util;
use 5.024;
use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures >;
use Time::HiRes 'time';
use Exporter 'import';
use Scalar::Util 'blessed';

our @EXPORT_OK = qw< args check_arrayref_of check_isa uuid >;

sub args (@as) { return { (@as && ref $as[0]) ? $as[0]->%* : @as } }

sub check_isa ($x, $class) {
   return '' if blessed($x) && $x->isa($class);
   return "not an instance of $class";
}

sub check_arrayref_of ($x, $class) {
   return "not an array reference <$x>" unless ref($x) eq 'ARRAY';
   for my $item ($x->@*) {
      my $check = check_isa($item, $class) or next;
      return $check;
   }
   return '';
}

sub uuid ($x = {}) { sprintf '%s-%s-%03d', "$x", time(), rand(1000) }

1;
