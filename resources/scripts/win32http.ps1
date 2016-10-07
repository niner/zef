param (
    [String]$url = $(throw "-url is required."),
    [String]$out = $(throw "-out is required."),
    [Int32]$timeout = 0
)

$progressPreference = 'silentlyContinue' # hide progress output
$http_proxy = $env:http_proxy;

if ( $http_proxy -ne $null ) {
    Invoke-WebRequest -Uri $url -OutFile $out -Proxy -TimeoutSec $timeout
} else {
    Invoke-WebRequest -Uri $url -OutFile $out -TimeoutSec $timeout
}
