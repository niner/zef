use Zef;

class Zef::Test does Pluggable does Phaser {
    method test($path, :@includes, Supplier :$logger) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;

        .pre($path, @includes, $logger) for self!list-plugins.grep({
          $_ ~~ Phaser && $_.^can('pre') && 
          $_.^can('types') && $_.types.grep($?CLASS);
        });

        my $tester = self.plugins.first(*.test-matcher($path));
        die "No testing backend available" unless ?$tester;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, payload => self, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => EXTRACT, phase => LIVE, message => $out }) }
            $tester.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => EXTRACT, phase => LIVE, message => $err }) }
        }

        my @got = try $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        .post($path, @includes, $logger, $tester, @got) for self!list-plugins.grep({
          $_ ~~ Phaser && $_.^can('post') &&
          $_.^can('types') && $_.types.grep($?CLASS);
        });

        @got;
    }
}
