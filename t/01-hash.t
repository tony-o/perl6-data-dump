#!/usr/bin/env perl6

use Test;
use Data::Dump;
plan 5;

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

my $expected-hash = Q:to/END/;
{
  "" => "bar".Str,
}
END
my %hash = "" => 'bar';
is Dump(%hash, :color(False)), $expected-hash.chomp, "Hash with a key which is an empty string";
my $expected = 'foo => "bar".Str';
my $expected2 = '11.Int => "bar".Str';
my $expected3 = '"" => "bar".Str';

my $set = Pair.new('foo', 'bar');
my $set1 = Pair.new(11, 'bar');
my $set2 = Pair.new('', 'bar');

is Dump($set, :color(False)), $expected, "Pairs with Str keys";
is Dump($set1, :color(False)), $expected2, "Pairs with Int keys";
is Dump($set2, :color(False)), $expected3, "Pair with an empty string as the key";

