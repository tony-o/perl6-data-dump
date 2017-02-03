#!/usr/bin/env perl6

use Test;
use Data::Dump;
plan 1;

my $out = Dump(@(
  { hello => 'world' },
  { one   => 2 },
), :color(False));

say $out;

ok $out eq "[\n  \{\n    hello => \"world\".Str,\n  },\n  \{\n    one => 2.Int,\n  },\n]";
