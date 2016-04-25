module Data::Dump {
  my $colorizor = sub (Str $s) { '' };
  
  try {
    require Terminal::ANSIColor;
    $colorizor = GLOBAL::Terminal::ANSIColor::EXPORT::DEFAULT::<&color>;
  }

  sub re-o ($o) {
    $o // 'undef';
  }

  sub key ($o) {
    return $colorizor("red") ~ re-o($o) ~ $colorizor("reset");
  }

  sub sym ($o) {
    return $colorizor("bold white") ~ re-o($o) ~ $colorizor("reset");
  }

  sub val ($o) { 
    return $colorizor("blue") ~ re-o($o) ~ $colorizor("reset");
  }

  sub what ($o) {
    return $colorizor("yellow") ~ re-o($o) ~ $colorizor("reset");
  }

  sub Dump ($obj, Int :$indent? = 2, Int :$ilevel? = 0, Bool :$color? = True, Int :$max-recursion? = 50, Bool :$gist = False) is export {
    return '...' if $max-recursion == $ilevel;
    temp $colorizor = sub (Str $s) { '' } unless $color;
    try {
      require 'Terminal::ANSIColor';
    };
    my Str $out   = '';
    my Str $space = (' ' x $indent) x $ilevel;
    my Str $spac2 = (' ' x $indent) x ($ilevel+1);
    if $obj.WHAT ~~ Hash && !$gist {
      my @keys    = $obj.keys.sort;
      my $spacing = @keys.map({ .chars }).max; 
      $out ~= "{$space}{sym('{')}" ~ (@keys.elems > 0 ?? "\n" !! "");
      for @keys -> $key {
        $out ~= $spac2 ~ "{key($key)}{ ' ' x ($spacing - $key.chars)} {sym('=>')} ";
        $out ~= (try { Dump($obj{$key}, :$gist, :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } // 'failure') ~ ",\n";
      }
      $out ~= "{@keys.elems > 0 ?? $space !! ' '}{sym('}')}\n";
    } elsif $obj.WHAT ~~ List && !$gist {
      $out ~= "{$space}{sym('[')}" ~ (@($obj).elems > 0 ?? "\n" !! "");
      for @($obj) -> $o {
        $out ~= Dump($o, :$gist, :$max-recursion, :$indent, ilevel => $ilevel+1).trim-trailing ~ ",\n"; 
      }
      $out ~= "{@($obj).elems > 0 ?? $space !! ' '}{sym(']')}\n";
    } elsif $obj.WHAT ~~ any(Int, Str, Rat, Numeric) && !$gist {
      my $what = $obj.WHAT.^name;
      $out ~= "{$space}{val($obj.perl // '<undef>')}\.{what($what)}\n";
    } elsif Any ~~ $obj.WHAT && !$gist {
      $out ~= $space ~ "(Any)\n";
    } elsif Method ~~ $obj.WHAT && !$gist {
      $out ~= $space ~ "{$obj.perl.subst(/'{' .+? $/, '')}\n";
    } else {
      $out ~= $space ~ sym("{$obj.^name} :: (") ~ "\n";
      if $gist {
        $out ~= "{$spac2}{$obj.gist},\n";
      } else { 
        my @attrs    = try { $obj.^attributes.sort({ $^x.Str cmp $^y.Str }) } // @();
        my @meths    = try { $obj.^methods.grep({ .^can('Str') }).sort({ $^x.gist.Str cmp $^y.gist.Str }) } // @();
        my @attr-len = @attrs.map({ next unless .so && .^can('Str'); .Str.chars });
        my @meth-len = @meths.map({ next unless .^can('gist'); .gist.Str.chars });
        my $spacing  = (@attr-len, @meth-len).max;


        for @attrs -> $attr {
          $out ~= "{$spac2}{key($attr)}{ ' ' x ($spacing - ($attr.so ?? $attr.Str.chars !! 0)) } => ";
          $out ~= ( try { Dump($attr.get_value($obj), :$gist, :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } // 
                    try { Dump($attr.hash, :$gist, :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } //
                    'undefined') ~ ",\n";
        }

        $out ~= "\n" if @attrs.elems > 0;
        for @meths -> $meth {
          my $sig = $meth.signature.params[1..*-2].map({ 
            .gist.Str.subst(/'{ ... }'/, .default ~~ Callable ?? .default.() !! ''); 
          }).join(sym(', ') ~ $colorizor('blue'));

          $out ~= "{$spac2}{sym('method')} {key($meth.gist.Str)} ({val($sig)}) returns {what($meth.returns.WHAT.^name)} {sym('{...}')},\n";
        } 
      }

      $out ~= "{$space}{sym(')')}\n";
    }
    $out .=trim if ($ilevel == 0);
    return $out;
  }
}

=begin pod

=head1 Data::Dump for perl6

that's right folks, here's a quicky for your data dump needs.  if you have
Term::ANSIColor installed then the output will be so colorful your eyes
might bleed.

feel free to submit bugs or make suggestions, if you submit a bug please
provide a concise example that replicates the problem and i'll add some
tests and make this thing better.

=head2 options

=item C<indent>

default: C<2>

    perl6
    <...>
    say Dump({ some => object }, :indent(4));
    <...>

=item C<max-recursion>

default: C<50>

    perl6
    <...>
    say Dump({ some => object }, :max-recursion(3));
    <...>

=item C<color>

default: C<True>

This will override the default decision to use color on the output if
C<Term::ANSIColor> is installed.  Passing a value of C<False> will ensure
that the output is vanilla.

    perl6
    <...>
    say Dump({ some => object }, :color(False));
    <...>

=head3 C<gist>

default: C<False>

This will override the default object determination and output and use the output of C<.gist>

 perl6
 <...>
 say Dump({ some => object }, :gist);
 <...>



=head2 usage

    use Data::Dump;

    say Dump(%(
      key1 => 'value1',
      key256 => 1,
    ));

output:

    {
      key1   => "value1".Str,
      key256 => 1.Int,
    }

note: if you have Term::ANSIColor installed then it's going to be amazing.
so, prepare yourself.

=head2 oh you want to C<Dump> your custom class?

here you go, dude

    use Data::Dump;

    class E {
      has $.public;
      has Int $!private = 5;
      method r(Str $a) { };
      method s($b, :$named? = 5) { };
      method e returns Int { say $!private; };
    };

    say Dump(E.new);

output:

    E :: (
      $!private => 5.Int,
      $!public  => (Any),

      method e () returns Int {...},
      method public () returns Mu {...},
      method r (Str $a) returns Mu {...},
      method s (Any $b, Any :named($named) = 5) returns Mu {...},
    )

=end pod
