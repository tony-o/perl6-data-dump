#!/usr/bin/env perl6

use Test;
use Data::Dump;

plan 1;

class E {
  has $.public;
  has Int $!private = 5;

  method r(Str $a) { };
  method s($b, :$named? = 5) { };
  method e returns Int { say $!private; };
};

my $out = Dump(E.new, :color(False));

ok $out eq "E :: (\n  \$!private => 5.Int,\n  \$!public  => (Any),\n\n  method e () returns Int \{...},\n  method public () returns Mu \{...},\n  method r (Str \$a) returns Mu \{...},\n  method s (Any \$b, Any :named(\$named) = 5) returns Mu \{...},\n)";

# vi:syntax=perl6
