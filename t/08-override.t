#!/usr/bin/env perl6

BEGIN { %*ENV<DATA_DUMP> = ''; }
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

my $d;
my $null-s = Dump($d, :!color);
my $expected = chomp qq:to/EXPECT/;
E :: (
  \$!private => 10,
  \$!private2 => Str:hello,
  \$!public => $null-s,

  e ()
  public ()
  r ()
  s ()
)
EXPECT

ok $out eq $expected, "got expected data structure";

is Dump(Mu), '(Mu)', 'Can dump an undefined Mu type object';
is Dump(Nil), '(Nil)', 'Can dump an undefined Any type object';;

# vi:syntax=perl6
