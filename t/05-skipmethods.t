#!/usr/bin/env perl6

use Test;
use Data::Dump;

plan 3;

class E {
  has $.public;
  has Int $!private = 5;

  method r(Str $a) { };
  method s($b, :$named? = 5) { };
  method e returns Int { say $!private; };
};

my $out = Dump(E.new, :color(False), :skip-methods);

my $expected = "E :: (\n  \$!private => 5.Int,\n  \$!public => (Nil),\n\n)";

ok $out eq $expected, "got expected data structure" or die $out;

class F {
  has E $.e;
  method x(Str $a) { };
}

$out = Dump(F.new(:e(E.new)), :color(False), :skip-methods);

$expected = "F :: (\n  \$!e => E :: (\n    \$!private => 5.Int,\n    \$!public => (Nil),\n\n  ),\n\n)";

ok $out eq $expected, "got expected nested data structure" or die $out;

role G {
  has $!g;
}

class H does G {
}

$expected = "H :: (\n  \$!g => undefined,\n\n)";
$out = Dump(H, :!color, :skip-methods);

ok $out eq $expected, "role stuff still is recognized in class" or die $out.perl;

# vi:syntax=perl6
