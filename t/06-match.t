#!/usr/bin/env perl6

BEGIN { %*ENV<DATA_DUMP> = ''; }
use Test;
use Data::Dump;

plan 1;

my $match = 'hello world' ~~ /'o w'/;

my $out = Dump($match, :color(False), :skip-methods);
my $expected = chomp q:to/EXPECT/;
Match :: (
  made => (Nil),
  pos  => 7.Int,
  hash => { },
  from => 4.Int,
  list => [ ],
  orig => "hello world".Str,
)
EXPECT

ok $out eq $expected, "special handling for Match" or die $out.perl;

# vi:syntax=perl6
