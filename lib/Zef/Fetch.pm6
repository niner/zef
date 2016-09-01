use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    method fetch($uri, $save-as, Supplier :$logger) {
        .pre($uri, $save-as, $logger) for self!list-plugins.grep({
          $_ ~~ Phased && $_.^can('pre') && 
          $_.^can('types') && $_.types.grep($?CLASS);
        });
        my $fetcher = self.plugins.first(*.fetch-matcher($uri));

        die "No fetching backend available" unless ?$fetcher;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => FETCH, phase => START, payload => self, message => "Fetching with plugin: {$fetcher.^name}" });
            $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, message => $out }) }
            $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, message => $err }) }
        }

        my $got = $fetcher.fetch($uri, $save-as);

        $fetcher.stdout.done;
        $fetcher.stderr.done;

        .post($uri, $save-as, $logger, $fetcher, $got) for self!list-plugins.grep({
          $_ ~~ Phased && $_.^can('post') && 
          $_.^can('types') && $_.types.grep($?CLASS);
        });
        return $got;
    }
}
