function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,4}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "�e�X�g�p�^�[���ԍ�������Γ��͂��Ă��������B (0001) "
        
        if ($pattern_no -eq "") {
            Write-Host "�p�^�[���ԍ��̓��͂��ȗ����܂����B�p�^�[���ԍ�0001���g�p���܂��B"
            return "P0001"
        }
        
        $pattern_no = "000$($pattern_no.trim())"
        $pattern_no = $pattern_no.Substring($pattern_no.Length - 4, 4)

        
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