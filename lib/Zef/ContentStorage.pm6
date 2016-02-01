use Zef;

class Zef::ContentStorage does Pluggable {
    has $.fetcher is rw;
    has $.cache   is rw;

    # Like search, but meant to return a single result for each specific identity string
    # whereas search is meant to search more fields and give many results to choose from
    method candidates(Bool :$upgrade, *@identities) {
        my @results = gather for self!plugins -> $storage {
            for $storage.search(|@identities, :max-results(1)) -> $result {
                take $result;
            }
        }
    }

    # todo: Find a better way to allow plugins access to other plugins
    method !plugins {
        cache gather for self.plugins {
            .fetcher //= $!fetcher if .^can('fetcher');
            .cache   //= $!cache   if .^can('cache');
            take $_;
        }
    }

    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @results = eager gather for self!plugins -> $storage {
            take $_ for $storage.search(|@identities, |%fields, :$max-results);
        }
        |@results;
    }

    method store(*@dists) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(|@dists);
        }
    }

    method update(*@names) {
        # todo: tag on `name` from config to plugins to enable filter by name
        # +@names
        #    ?? self.plugins.grep(*.<name> ~~ any(@names)).map(*.?update)
        #    !! self.plugins.map(*.?update);
        self!plugins.map(*.?update);
    }
}
