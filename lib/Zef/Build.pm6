use Zef;

class Zef::Build does Pluggable {
    method build($path, :@includes, Supplier :$logger) {
        die "Can't build non-existent path: {$path}" unless $path.IO.e;

        .pre($path, @includes, $logger) for self!list-plugins.grep({
          $_ ~~ Phaser && $_.^can('pre') && 
          $_.^can('types') && $_.types.grep($?CLASS);
        });

        my $builder = self.plugins.first(*.build-matcher($path));
        die "No building backend available" unless ?$builder;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => BUILD, phase => START, payload => self, message => "Building with plugin: {$builder.^name}" });
            $builder.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => BUILD, phase => LIVE, message => $out }) }
            $builder.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => BUILD, phase => LIVE, message => $err }) }
        }

        my $got = try $builder.build($path, :@includes);

        $builder.stdout.done;
        $builder.stderr.done;

        .post($path, @includes, $logger, $builder, $got) for self!list-plugins.grep({
          $_ ~~ Phaser && $_.^can('post') && 
          $_.^can('types') && $_.types.grep($?CLASS);
        });

        $got;
    }
}
