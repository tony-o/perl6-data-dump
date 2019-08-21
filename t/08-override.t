#!/usr/bin/env perl6

use Test;
use Data::Dump;

plan 3;

class E {
  has $.public;
  has Int $!private = 5;
  has Str $!private2 = 'hello';

  method r(Str $a) { };
  method s($b, :$named? = 5) { };
  method e returns Int { say $!private; };
  method !p(Int $x) { };
};


my %overrides = (
  Method => sub ($meth) {
    $meth.name ~ ' ()';
  },
  Int => sub ($val) { $val * 2; },
  Str => sub ($val) { "Str:$val"; },
);
my $out = Dump(E.new, :color(False), :no-postfix, :%overrides) ;

# Autogenerated method BUILDALL is listed starting with Rakudo 2017.10
my $expected = "E :: (\n  \$!private => 10,\n  \$!private2 => Str:hello,\n  \$!public => (Nil),\n\n  e ()\n  public ()\n  r ()\n  s ()\n)";

Dump(E.new, :no-postfix, :%overrides).say;

ok $out eq $expected, "got expected data structure" or die $out;

is Dump(Mu), '(Mu)', 'Can dump an undefined Mu type object';
is Dump(Nil), '(Nil)', 'Can dump an undefined Any type object';;

# vi:syntax=perl6