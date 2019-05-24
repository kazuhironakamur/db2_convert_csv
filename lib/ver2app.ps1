# 呼び出し元シェルからの相対パスになるので注意
. .\lib\ver2functions.ps1

function get_function_name($f_id) {
    $r = $functions.$f_id
    
    $esc_chars = @(" ", "　", "\\")
    foreach ($c in $esc_chars) { $r = $r -replace $c, "" }

    return $r   
}

function function_id_is_valid($f_id) {
    return $f_id -match "^[a-z]_[a-z]{2}_\d{4}$"
}

function function_id_is_exist($f_id) {
    if ($functions.$f_id -eq $null) {
        return $False
    }
    
    return $True
}

function read_function_id($input_function_id) {
    while ($True) {
        $example = if ($input_function_id -ne $null) {
            "入力を省略すると直近の機能ID 【$input_function_id】 を使用します。 (X_XX_0000) "
        }
        else {
            '(X_XX_0000)'
        }
        
        $function_id = read-host "対象の機能IDを入力してください。$example "
        $function_id = $function_id.trim().ToUpper()

        if ($function_id -eq "") {
            if ($input_function_id -ne $null) { return $input_function_id }

            Write-Host -ForegroundColor Red "機能IDは必須です。"
            continue
        }

        if ($(function_id_is_valid $function_id) -eq $False) {
            Write-Host -ForegroundColor Red "機能IDの形式が正しくありません。"
            continue
        }

        if ($(function_id_is_exist $function_id) -eq $False) {
            Write-Host -ForegroundColor Red "指定された機能IDは定義されていません。"
            continue
        }

        break
    }
    
    return $function_id
}