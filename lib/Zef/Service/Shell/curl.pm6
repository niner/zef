use Zef;
use Zef::Shell;

class Zef::Service::Shell::curl is Zef::Shell does Fetcher does Probeable does Messenger {
    has $.timeout;

    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $curl-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('curl', '--help');
        }
        ?$curl-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;

        my @args = ['--silent',] andthen {
            .append('--max-time', $!timeout)                  if $!timeout;
            .append('--connect-timeout', max($!timeout, 300)) if $!timeout;
        }

        my $proc = $.zrun('curl', |@args, '-o', $save-as, $url);
        $ = ?$proc ?? $save-as !! False;
    }
}
