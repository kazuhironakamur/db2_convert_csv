$__pattern_no_max_length = 6

function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,$($__pattern_no_max_length)}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "テストパターン番号があれば入力してください。 (1～$('9' * $__pattern_no_max_length)) "
        
        if ($pattern_no -eq "") {
            $pattern_no = '0' * ($__pattern_no_max_length - 1) + '1'
            info "パターン番号の入力を省略しました。パターン番号$($pattern_no)を使用します。"
            break
        }
        
        $pattern_no = '0' * ($__pattern_no_max_length - 1) + $($pattern_no.trim())
        $pattern_no = $pattern_no.Substring($pattern_no.Length - $__pattern_no_max_length, $__pattern_no_max_length)

        
        if ($(pattern_no_is_valid $pattern_no) -eq $False) {
            error "パターン番号の形式が正しくありません。"
            continue
        }

        if ([int]$pattern_no -le 0) {
            error "パターン番号は1以上の正の整数を指定してください。"
            continue
        }

        break
    }
    
    return "P$pattern_no"
}

function create_directory($directory_name) {
    if ($directory_name -eq "") {
        error "ディレクトリの作成に失敗しました。"
        error "ディレクトリ名が設定されていません。(Directory_name = $directory_name)"
    }

    if ($(test-path -PathType Container $directory_name) -eq $False) {
        new-item -ItemType Directory $directory_name | out-null
    }
}