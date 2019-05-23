# �Ăяo�����V�F������̑��΃p�X�ɂȂ�̂Œ���
. .\lib\ver2functions.ps1

function get_function_name($f_id) {
    $r = $functions.$f_id
    
    $esc_chars = @(" ", "�@", "\\")
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

function read_function_id() {
    while($True) {
        $function_id = read-host "�Ώۂ̋@�\ID����͂��Ă������� (X_XX_0000) "
        $function_id = $function_id.trim().ToUpper()

        if ($function_id -eq "") {
            Write-Host -ForegroundColor Red "�@�\ID�͕K�{�ł��B"
            continue
        }

        if ($(function_id_is_valid $function_id) -eq $False) {
            Write-Host -ForegroundColor Red "�@�\ID�̌`��������������܂���B"
            continue
        }

        if ($(function_id_is_exist $function_id) -eq $False) {
            Write-Host -ForegroundColor Red "�w�肳�ꂽ�@�\ID�͒�`����Ă��܂���B"
            continue
        }

        break
    }
    
    return $function_id
}