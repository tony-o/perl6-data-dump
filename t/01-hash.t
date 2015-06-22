#!/usr/bin/env perl6

use Test;
use Data::Dump;
plan 1;

my $out = Dump(%(
  a => 'a',
  b => 'b',
  hash => %(
    a => 'a',
    b => 'b',
    reallylongkey => 'key',
    hash => %(
      a => 'a',
      b => 5,
    ),
  ),
), :color(False));


ok $out eq "\{\n  a    => \"a\".Str,\n  b    => \"b\".Str,\n  hash => \{\n    a             => \"a\".Str,\n    b             => \"b\".Str,\n    hash          => \{\n      a => \"a\".Str,\n      b => 5.Int,\n    },\n    reallylongkey => \"key\".Str,\n  },\n}";
