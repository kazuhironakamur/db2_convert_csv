$__pattern_no_max_length = 6

function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,$($__pattern_no_max_length)}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "�e�X�g�p�^�[���ԍ�������Γ��͂��Ă��������B (1�`$('9' * $__pattern_no_max_length)) "
        
        if ($pattern_no -eq "") {
            $pattern_no = '0' * ($__pattern_no_max_length - 1) + '1'
            info "�p�^�[���ԍ��̓��͂��ȗ����܂����B�p�^�[���ԍ�$($pattern_no)���g�p���܂��B"
            break
        }
        
        $pattern_no = '0' * ($__pattern_no_max_length - 1) + $($pattern_no.trim())
        $pattern_no = $pattern_no.Substring($pattern_no.Length - $__pattern_no_max_length, $__pattern_no_max_length)

        
        if ($(pattern_no_is_valid $pattern_no) -eq $False) {
            error "�p�^�[���ԍ��̌`��������������܂���B"
            continue
        }

        if ([int]$pattern_no -le 0) {
            error "�p�^�[���ԍ���1�ȏ�̐��̐������w�肵�Ă��������B"
            continue
        }

        break
    }
    
    return "P$pattern_no"
}

function create_directory($directory_name) {
    if ($directory_name -eq "") {
        error "�f�B���N�g���̍쐬�Ɏ��s���܂����B"
        error "�f�B���N�g�������ݒ肳��Ă��܂���B(Directory_name = $directory_name)"
    }

    if ($(test-path -PathType Container $directory_name) -eq $False) {
        new-item -ItemType Directory $directory_name | out-null
    }
}