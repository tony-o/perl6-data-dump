#!/usr/bin/env perl6

use Test;
use Data::Dump;
plan 3;

my $out = Dump(%(
  a => 'a',
  b => %( b => 'b' ),
), :color(False), :gist);

ok $out eq "Hash :: (\n  \{a => a, b => \{b => b\}\},\n)", 'weird hash';

$out = Dump('foobar' ~~ m/foo(bar)/, :color(False), :gist);

ok $out eq "Match :: (\n  ｢foobar｣\n 0 => ｢bar｣,\n)", 'Match object';

$out = Dump(Pair.new(Mu, Mu), :color(False), :gist);

is-deeply $out, "Pair :: (\n  (Mu) => (Mu),\n)", "Pair with undefined keys";
