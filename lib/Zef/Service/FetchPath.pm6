use Zef;
use Zef::Utils::FileSystem;
use Zef::Utils::URI;

class Zef::Service::FetchPath does Fetcher does Messenger does Extractor {
    has $.timeout;

    # .is-absolute lets the app pass around absolute paths on windows and still work as expected
    method fetch-matcher($uri)   { $ = (?$uri.IO.is-absolute || ?$uri.lc.starts-with('.' | '/')) && $uri.IO.e }
    method extract-matcher($uri) { $ = (?$uri.IO.is-absolute || ?$uri.lc.starts-with('.' | '/')) && $uri.IO.d }

    method probe { True }

    method fetch($from, $to) {
        return False    if !$from.IO.e;
        return $from    if $from.IO.absolute eq $to.IO.absolute; # fakes a fetch
        my $dest-path = $from.IO.d ?? $to.IO.child("{$from.IO.absolute.IO.basename}_{time}") !! $to;
        mkdir($dest-path) if $from.IO.d && !$to.IO.e;

        # for consistency with all the remote stuff
        if $!timeout {
            my $promise = Promise.new;
            my $vow     = $promise.vow;
            await Promise.anyof(
                Promise.in($!timeout),
                start { $vow.keep(copy-paths($from, $dest-path).elems) }
            );
            die "timed out copying files" unless $promise.result;
        }
        else {
            return False unless copy-paths($from, $dest-path).elems;
        }

        $dest-path;
    }

    method extract($path, $save-as) {
        my $extracted-to = $save-as.IO.child($path.IO.basename).absolute;
        my @extracted = copy-paths($path, $extracted-to);
        +@extracted ?? $extracted-to !! False;
    }

    method list($path) {
        $ = list-paths($path, :f, :!d, :r);
    }
}
