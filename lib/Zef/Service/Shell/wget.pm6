use Zef;
use Zef::Shell;

class Zef::Service::Shell::wget is Zef::Shell does Fetcher does Probeable does Messenger {
    has $.timeout;

    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $wget-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('wget', '--help');
        }
        ?$wget-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;

        my @args = ['--quiet',] andthen {
            .append("--timeout=$!timeout") if $!timeout;
        }

        my $proc = $.zrun('wget', |@args, $url, '-O', $save-as);
        $ = ?$proc ?? $save-as !! False;
    }
}
