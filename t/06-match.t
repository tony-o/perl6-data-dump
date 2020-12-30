#!/usr/bin/env perl6

use Test;
use Data::Dump;

plan 1;

my $match = 'hello world' ~~ /'o w'/;

my $out = Dump($match, :color(False), :skip-methods);
my $expected = "Match :: (\n  made => (Nil),\n  pos  => 7.Int,\n  hash => \{ \},\n  from => 4.Int,\n  list => [ ],\n  orig => \"hello world\".Str,\n)";

ok $out eq $expected, "special handling for Match" or die $out.perl;

# vi:syntax=perl6
