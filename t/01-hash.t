#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Data::Dump;
plan 3;

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

my $expected = 'foo => "bar".Str';
my $expected2 = '11.Int => "bar".Str';

is Dump(Pair.new('foo', 'bar'), :color(False)), $expected, "Pairs with Str keys";
is Dump(Pair.new(11, 'bar'), :color(False)), $expected2, "Pairs with Int keys";

