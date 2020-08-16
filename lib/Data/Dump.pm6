module Data::Dump {
  my %provides-cache;
  my $colorizor = (try require Terminal::ANSIColor) === Nil
    && {''} || ::('Terminal::ANSIColor::EXPORT::DEFAULT::&color');

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

  sub pseudo-cache($obj) { #provide list of methods provided by parents
    my %r;
    for $obj.^mro[1..*] -> $x {
      if %provides-cache{$x.^name} {
        %provides-cache{$x.^name}.map({ %r{$_}.push($x.^name); });
      } else {
        $x.^methods.map({
          %provides-cache{$x.^name}.push($_.gist.Str);
          %r{$_.gist.Str}.push($x.^name);
        });
      }
    }
    %r;
  }

  multi Dump (Mu $obj,  Int :$indent? = 2, Int :$ilevel? = 0, Bool :$color? = True, Int :$max-recursion? = 50, Bool :$gist = False, Bool :$skip-methods = False, Bool :$no-postfix = False, :%overrides where { !$_.values.grep: * !~~ Sub } = {}, ) is export {
    return $obj.gist;
  }

  multi Dump (Any $obj, Int :$indent? = 2, Int :$ilevel? = 0, Bool :$color? = True, Int :$max-recursion? = 50, Bool :$gist = False, Bool :$skip-methods = False, Bool :$no-postfix = False, :%overrides where { !$_.values.grep: * !~~ Sub } = {}, ) is export {
    return '...' if $max-recursion == $ilevel;
    temp $colorizor = sub (Str $s) { '' } unless $color;
    try {
      require 'Terminal::ANSIColor';
    };
    my Str $out   = '';
    my Str $space = (' ' x $indent) x $ilevel;
    my Str $spac2 = (' ' x $indent) x ($ilevel+1);
    %overrides.map({ %overrides{$_.key.^name} //= $_.value; });
    if %overrides{$obj.^name}.defined {
      my %options;
      warn 'Overrides must contain only one positional parameter' if %overrides{$obj.^name}.signature.params.grep(*.positional).elems != 1;
      for %overrides{$obj.^name}.signature.params -> $param {
        next unless $param.named;
        next unless $param.name ~~ (qw<$indent $ilevel $color $max-recursion $gist $skip-methods $no-postfix %overrides>);
        %options{$param.substr(1)} = $::($param.substr(1));
      }
      $out ~= %overrides{$obj.^name}($obj, |%options) ~ "\n";
    } elsif $obj.WHAT ~~ Hash && !$gist {
      my @keys    = $obj.keys.sort;
      my $spacing = @keys.map({ .chars }).max;
      $out ~= "{$space}{sym('{')}" ~ (@keys.elems > 0 ?? "\n" !! "");
      for @keys -> $key {
        my $chars = $key.chars;
        $out ~= $spac2 ~ "{key($chars ?? $key !! '""')}{ ' ' x ($spacing - $key.chars)} {sym('=>')} ";
        $out ~= (try { Dump($obj{$key}, :%overrides, :$no-postfix, :$gist, :$color, :$max-recursion, :$indent, :$skip-methods, ilevel => $ilevel+1).trim; } // 'failure') ~ ",\n";
      }
      $out ~= "{@keys.elems > 0 ?? $space !! ' '}{sym('}')}\n";
    } elsif $obj.WHAT ~~ Pair && !$gist {
        my $key = $obj.key.WHAT ~~ Str
        ?? key($obj.key eq '' ?? '""' !! $obj.key)
        !! Dump($obj.key, :%overrides, :$gist, :$max-recursion, :$indent, :$skip-methods, :$color, :$no-postfix);
        $out ~= $key ~ ' => ' ~ Dump($obj.value, :%overrides, :$gist, :$max-recursion, :$indent, :$skip-methods, :$color, :$no-postfix);
    } elsif $obj.WHAT ~~ List && !$gist {
      $out ~= "{$space}{sym('[')}" ~ (@($obj).elems > 0 ?? "\n" !! "");
      for @($obj) -> $o {
        $out ~= Dump($o, :%overrides, :$no-postfix, :$color, :$gist, :$max-recursion, :$indent, :$skip-methods, ilevel => $ilevel+1).trim-trailing ~ ",\n";
      }
      $out ~= "{@($obj).elems > 0 ?? $space !! ' '}{sym(']')}\n";
    } elsif $obj.WHAT ~~ any(Int, Str, Rat, Numeric) && !$gist {
      my $what = $obj.WHAT.^name;
      $out ~= "{$space}{$obj.defined ?? val($obj.perl) ~ ($no-postfix ?? '' !! '.'~what($what)) !! what($what) ~ ':U' }\n";
    } elsif (Nil|Any) ~~ $obj.WHAT && !$gist {
      $out ~= $space ~ "({Nil ~~ $obj.WHAT ?? 'Nil' !! 'Any'})\n";
    } elsif (Sub|Method) ~~ $obj.WHAT && !$gist {
      $out ~= $space ~ "{$obj.perl.subst(/'{' .+? $/, '')}\n";
    } elsif Range ~~ $obj.WHAT && !$gist {
      $out ~= "{$space}{$obj.min}{$obj.excludes-min??'^'!!''}..{$obj.excludes-max??'^'!!''}{$obj.max}";
    } elsif $obj ~~ IO::Path && !$gist {
      my $what = $obj.WHAT.^name;
      $out ~= “{$space}{val($obj.perl // '<undef>')}{$no-postfix ?? '' !! '.'~what($what)} :absolute("{$obj.absolute}")\n”;
    } elsif $obj ~~ Match|Grammar && !$gist {
      $out ~= $space ~ sym("{$obj.^name} :: (") ~ "\n";
      my @props = qw<made pos hash from list orig>.grep({ $obj.^can($_) });
      my $asp   = @props.map({ .chars }).max;
      for @props -> $p {
        $out ~= "{$spac2}{key($p)}{ ' ' x ($asp - $p.chars) } => ";
        $out ~= (try {
          CATCH { .say; }
          Dump($obj.^can($p)[0].($obj), :%overrides, :$no-postfix, :$color, :$gist, :$max-recursion, :$indent, :$skip-methods, ilevel => $ilevel+1).trim;
        } // 'Failure') ~ ",\n";
      }
      $out ~= "{$space}{sym(')')}\n";
    } else {
      $out ~= $space ~ sym("{$obj.^name} :: (") ~ "\n";
      if $gist {
        $out ~= "{$spac2}{$obj.gist},\n";
      } else {
        my @attrs    = try { $obj.^attributes.sort({ $^x.Str cmp $^y.Str }) } // @();
        my @meths    = try { $obj.^methods(:local).sort({ $^x.gist.Str cmp $^y.gist.Str }) } // @();
        my @attr-len = @attrs.map({ next unless .so && .^can('Str'); .Str.chars });
        my @meth-len = @meths.map({ next unless .^can('gist'); .gist.Str.chars });
        my $spacing  = (@attr-len, @meth-len).max;


        for @attrs.sort -> $attr {
          next unless $attr;
          $out ~= "{$spac2}{key($attr)}{ ' ' x ($spacing - ($attr.so ?? $attr.Str.chars !! 0)) } => ";
          $out ~= ( try { Dump($attr.get_value($obj), :%overrides, :$no-postfix, :$color, :$gist, :$max-recursion, :$indent, :$skip-methods, ilevel => $ilevel+1).trim; } //
                    try { Dump($attr.hash, :%overrides, :$no-postfix, :$color, :$gist, :$max-recursion, :$indent, :$skip-methods, ilevel => $ilevel+1).trim; } //
                    'undefined') ~ ",\n";
        }

        $out ~= "\n" if @attrs.elems > 0;
        if !$skip-methods {
          my %parent-methods = pseudo-cache($obj);
          for @meths.sort({$^a.gist.Str cmp $^b.gist.Str}) -> $meth {
            next if %parent-methods{$meth.gist.Str};
            if %overrides{Method.^name} {
              my %options;
              warn 'Overrides must contain only one positional parameter' if %overrides{Method.^name}.signature.params.grep(*.positional).elems != 1;
              for %overrides{Method.^name}.signature.params -> $param {
                next unless $param.named;
                next unless $param.name ~~ (qw<$indent $ilevel $color $max-recursion $gist $skip-methods $no-postfix %overrides>);
                %options{$param.substr(1)} = $::($param.substr(1));
              }
              $out ~= $spac2 ~ %overrides{Method.^name}($meth, |%options) ~ "\n";
            } else {
              if $meth.^can('signature') {
                my $sig = $meth.signature.params[1..*-2].map({
                  .gist.Str.subst(/'{ ... }'/, do with .default { .() } else { '' });
                }).join(sym(', ') ~ $colorizor('blue'));
                $out ~= "{$spac2}{sym('method')} {key($meth.gist.Str)} ({val($sig)}) returns {what($meth.returns.WHAT.^name)} {sym('{...}')},\n";
              } else {
                CATCH { $out ~= "{$spac2}{sym('method')} {key($meth.gist.Str)},\n"; };
              }
            }
          }
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

=head3 C<no-postfix>

default: C<False>

This will shorten C<Str|Int|Rat|Numeric> output from C<5.Int|"H".Str> to simply C<5|"H">

=head3 C<skip-methods>

default: C<False>

This will skip the methods if you dump custom classes.

=head3 C<overrides>

default: C<{}>

This will allow you to override how DD dumps certain types of objects.

 perl6
 Dump($object, overrides => {
   Int => sub ($int) { return $int * 2; },
   Str => sub ($str) { return "'$str'"; },
   # etc.
 });

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
