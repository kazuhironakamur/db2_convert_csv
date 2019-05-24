$__pattern_no_max_length = 6

function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,$($__pattern_no_max_length)}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "�e�X�g�p�^�[���ԍ�������Γ��͂��Ă��������B (1�`$('9' * $__pattern_no_max_length)) "
        
        if ($pattern_no -eq "") {
            $pattern_no = '0' * ($__pattern_no_max_length - 1) + '1'
            Write-Host "�p�^�[���ԍ��̓��͂��ȗ����܂����B�p�^�[���ԍ�$($pattern_no)���g�p���܂��B"
            break
        }
        
        $pattern_no = '0' * ($__pattern_no_max_length - 1) + $($pattern_no.trim())
        $pattern_no = $pattern_no.Substring($pattern_no.Length - $__pattern_no_max_length, $__pattern_no_max_length)

        
        if ($(pattern_no_is_valid $pattern_no) -eq $False) {
            Write-Host -ForegroundColor Red "�p�^�[���ԍ��̌`��������������܂���B"
            continue
        }

        if ([int]$pattern_no -le 0) {
            Write-Host -ForegroundColor Red "�p�^�[���ԍ���1�ȏ�̐��̐������w�肵�Ă��������B"
            continue
        }

        break
    }
    
    return "P$pattern_no"
}