module Data::Dump {
  my $colorizor = sub (Str $s) { '' };
  
  {
    require Term::ANSIColor;
    $colorizor = GLOBAL::Term::ANSIColor::EXPORT::DEFAULT::<&color>;
  }

  sub key ($o) {
    return $colorizor("red") ~ $o ~ $colorizor("reset");
  }

  sub sym ($o) {
    return $colorizor("bold white") ~ $o ~ $colorizor("reset");
  }

  sub val ($o) { 
    return $colorizor("blue") ~ $o ~ $colorizor("reset");
  }

  sub what ($o) {
    return $colorizor("yellow") ~ $o ~ $colorizor("reset");
  }

  sub Dump ($obj, Int :$indent? = 2, Int :$ilevel? = 0, Bool :$color? = True) is export {
    temp $colorizor = sub (Str $s) { '' } unless $color;
    try {
      require 'Term::ANSIColor';
    };
    my Str $out   = '';
    my Str $space = (' ' x $indent) x $ilevel;
    my Str $spac2 = (' ' x $indent) x ($ilevel+1);
    if $obj.WHAT ~~ Hash {
      my @keys    = $obj.keys.sort;
      my $spacing = @keys.map({ .chars }).max; 

      $out ~= "{$space}{sym('{')}\n";
      for @keys -> $key {
        $out ~= $spac2 ~ "{key($key)}{ ' ' x ($spacing - $key.chars)} {sym('=>')} ";
        $out ~= Dump($obj{$key}, :$indent, ilevel => $ilevel+1).trim ~ ",\n";
      }
      $out ~= "{$space}{sym('}')}\n";
    } elsif $obj.WHAT ~~ List {
      $out ~= "{$space}{sym('[')}\n";
      for @($obj) -> $o {
        $out ~= Dump($o, :$indent, ilevel => $ilevel+1).trim-trailing ~ ",\n"; 
      }
      $out ~= "{$space}{sym(']')}\n";
    } elsif $obj.WHAT ~~ any(Int, Str, Rat) {
      my $what = $obj.WHAT.^name;
      $out ~= "{$space}{val($obj.perl // '<undef>')}\.{what($what)}\n";
    } elsif Any ~~ $obj.WHAT {
      $out ~= $space ~ "(Any)\n";

    } else {
      $out ~= $space ~ sym("{$obj.^name} :: (") ~ "\n";
      my @attrs   = try { $obj.^attributes.sort({ $^x.Str cmp $^y.Str }) } // @();
      my @meths   = try { $obj.^methods.grep({ .^can('Str') }).sort({ $^x.gist.Str cmp $^y.gist.Str }) } // @();
      my $spacing = (@attrs.map({ next unless .^can('Str'); .Str.chars }), @meths.map({ next unless .^can('gist'); .gist.Str.chars })).max;

      for @attrs -> $attr {
        $out ~= "{$spac2}{key($attr)}{ ' ' x ($spacing - $attr.Str.chars) } => ";
        $out ~= ( try { Dump($attr.get_value($obj), :$indent, ilevel => $ilevel+1).trim } // 
                  try { Dump($attr.hash, :$indent, ilevel => $ilevel+1).trim } //
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
