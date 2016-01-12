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

  sub Dump ($obj, Int :$indent? = 2, Int :$ilevel? = 0, Bool :$color? = True, Int :$max-recursion? = 50) is export {
    return '...' if $max-recursion == $ilevel;
    temp $colorizor = sub (Str $s) { '' } unless $color;
    try {
      require 'Terminal::ANSIColor';
    };
    my Str $out   = '';
    my Str $space = (' ' x $indent) x $ilevel;
    my Str $spac2 = (' ' x $indent) x ($ilevel+1);
    if $obj.WHAT ~~ Hash {
      my @keys    = $obj.keys.sort;
      my $spacing = @keys.map({ .chars }).max; 
      $out ~= "{$space}{sym('{')}" ~ (@keys.elems > 0 ?? "\n" !! "");
      for @keys -> $key {
        $out ~= $spac2 ~ "{key($key)}{ ' ' x ($spacing - $key.chars)} {sym('=>')} ";
        $out ~= (try { Dump($obj{$key}, :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } // 'failure') ~ ",\n";
      }
      $out ~= "{@keys.elems > 0 ?? $space !! ' '}{sym('}')}\n";
    } elsif $obj.WHAT ~~ List {
      $out ~= "{$space}{sym('[')}" ~ (@($obj).elems > 0 ?? "\n" !! "");
      for @($obj) -> $o {
        $out ~= Dump($o, :$max-recursion, :$indent, ilevel => $ilevel+1).trim-trailing ~ ",\n"; 
      }
      $out ~= "{@($obj).elems > 0 ?? $space !! ' '}{sym(']')}\n";
    } elsif $obj.WHAT ~~ any(Int, Str, Rat, Numeric) {
      my $what = $obj.WHAT.^name;
      $out ~= "{$space}{val($obj.perl // '<undef>')}\.{what($what)}\n";
    } elsif Any ~~ $obj.WHAT {
      $out ~= $space ~ "(Any)\n";
    } elsif Method ~~ $obj.WHAT {
      $out ~= $space ~ "{$obj.perl.subst(/'{' .+? $/, '')}\n";
    } else {
      $out ~= $space ~ sym("{$obj.^name} :: (") ~ "\n";
      my @attrs    = try { $obj.^attributes.sort({ $^x.Str cmp $^y.Str }) } // @();
      my @meths    = try { $obj.^methods.grep({ .^can('Str') }).sort({ $^x.gist.Str cmp $^y.gist.Str }) } // @();
      my @attr-len = @attrs.map({ next unless .so && .^can('Str'); .Str.chars });
      my @meth-len = @meths.map({ next unless .^can('gist'); .gist.Str.chars });
      my $spacing  = (@attr-len, @meth-len).max;


      for @attrs -> $attr {
        $out ~= "{$spac2}{key($attr)}{ ' ' x ($spacing - ($attr.so ?? $attr.Str.chars !! 0)) } => ";
        $out ~= ( try { Dump($attr.get_value($obj), :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } // 
                  try { Dump($attr.hash, :$max-recursion, :$indent, ilevel => $ilevel+1).trim; } //
                  'undefined') ~ ",\n";
      }

      $out ~= "\n" if @attrs.elems > 0;
      for @meths -> $meth {
        my $sig = $meth.signature.params[1..*-2].map({ 
          .gist.Str.subst(/'{ ... }'/, .default ~~ Callable ?? .default.() !! ''); 
        }).join(sym(', ') ~ $colorizor('blue'));

        $out ~= "{$spac2}{sym('method')} {key($meth.gist.Str)} ({val($sig)}) returns {what($meth.returns.WHAT.^name)} {sym('{...}')},\n";
      } 

      $out ~= "{$space}{sym(')')}\n";
    }
    $out .=trim if ($ilevel == 0);
    return $out;
  }
}
