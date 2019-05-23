function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,4}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "テストパターン番号があれば入力してください。 (0001) "
        
        if ($pattern_no -eq "") {
            Write-Host "パターン番号の入力を省略しました。パターン番号0001を使用します。"
            return "P0001"
        }
        
        $pattern_no = "000$($pattern_no.trim())"
        $pattern_no = $pattern_no.Substring($pattern_no.Length - 4, 4)

        
        if ($(pattern_no_is_valid $pattern_no) -eq $False) {
            Write-Host -ForegroundColor Red "パターン番号の形式が正しくありません。"
            continue
        }

        if ([int]$pattern_no -le 0) {
            Write-Host -ForegroundColor Red "パターン番号は1以上の正の整数を指定してください。"
            continue
        }

        break
    }
    
    return "P$pattern_no"
}