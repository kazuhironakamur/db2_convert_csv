function log($msg, $color) {
    if ($color -eq $null) {
        Write-Host "[$(get-date -format "yyyy/MM/dd HH:mm:ss.fff")] $msg"
    }
    else {
        Write-Host -ForegroundColor $color "[$(get-date -format "yyyy/MM/dd hh:mm:ss.fff")] $msg"
    }
}

function info($msg) {
    log $msg $null
}

function warn($msg) {
    log $msg "Yellow"
}

function error($msg) {
    log $msg "Red"
}