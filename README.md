# Data::Dump 

[![Build Status](https://travis-ci.org/tony-o/perl6-data-dump.svg?branch=master)](https://travis-ci.org/tony-o/perl6-data-dump)

## for perl6

that's right folks, here's a quicky for your data dump needs.  if you have Terminal::ANSIColor installed then the output will be so colorful your eyes might bleed.

feel free to submit bugs or make suggestions, if you submit a bug please provide a concise example that replicates the problem and i'll add some tests and make this thing better.

## options

### `indent`

default: `2`

```perl6
<...>
say Dump({ some => object }, :indent(4));
<...>
```

### `max-recursion`

default: `50`

```perl6
<...>
say Dump({ some => object }, :max-recursion(3));
<...>
```

### `color`

default: `True`

This will override the default decision to use color on the output if `Terminal::ANSIColor` is installed.  Passing a value of `False` will ensure that the output is vanilla.

```perl6
<...>
say Dump({ some => object }, :color(False));
<...>
```

### `gist`

default: `False`

This will override the default object determination and output and use the output of `.gist`

```perl6
<...>
say Dump({ some => object}, :gist);
<...>
```

### `skip-methods`

default: `False`

This will skip the methods if you dump custom classes.

```perl6
<...>
say Dump($object, :skip-methods(True));
<...>
```

## usage

```perl6
use Data::Dump;

say Dump(%( 
  key1 => 'value1',
  key256 => 1,
));
```

output:
```
{
  key1   => "value1".Str,
  key256 => 1.Int,
}
```
note: if you have Terminal::ANSIColor installed then it's going to be amazing. so, prepare yourself.

## oh you want to ```Dump``` your custom class?

here you go, dude

```perl6
use Data::Dump;

class E {
  has $.public;
  has Int $!private = 5;
  method r(Str $a) { };
  method s($b, :$named? = 5) { };
  method e returns Int { say $!private; };
};

say Dump(E.new);
```

output:
```
E :: (
  $!private => 5.Int,
  $!public  => (Any),

  method e () returns Int {...},
  method public () returns Mu {...},
  method r (Str $a) returns Mu {...},
  method s (Any $b, Any :named($named) = 5) returns Mu {...},
)
```

