use v6;
use Test;
plan 1;

use Zef::Net::HTTP::Grammar;
use Zef::Net::HTTP::Actions;


subtest {
    my $response = q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Host: www.http.header.free.fr}
        ~ "\r\n" ~ q{Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,}
        ~ "\r\n" ~ q{Accept-Language: Fr}
        ~ "\r\n" ~ q{Accept-Encoding: gzip, deflate}
        ~ "\r\n" ~ q{User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)}
        ~ "\r\n" ~ q{Connection: Keep-Alive}
        ~ "\r\n\r\n";
    my $actions = Zef::Net::HTTP::Actions.new;

    my $http = Zef::Net::HTTP::Grammar.parse($response, :$actions);

    my %header = $http.<HTTP-message>.<header-field>>>.made;
    is %header<Host>,            'www.http.header.free.fr';
    is %header<Accept>,          'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,';
    is %header<Accept-Language>, 'Fr';
    is %header<Accept-Encoding>, 'gzip, deflate';
    is %header<User-Agent>,      'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';
    is %header<Connection>,      'Keep-Alive';

}, 'Header basic key => value';




done();
