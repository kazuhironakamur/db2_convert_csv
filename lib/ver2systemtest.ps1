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

function create_evidence_directories($function_id, $function_name, $pattern_no, $compare_times, $detail) {
    foreach ($env in @('genkou', 'cloud')) {
        $evidence_dir = "$($function_id)_$($function_name)\$($pattern_no)\"
        $work_dir = "$($evidence_dir)\WORK\$env" -replace "genkou", "���s" -replace "cloud", "�N���E�h"
        create_directory $work_dir
        create_directory $("$evidence_dir\�G�r�f���X\$env" -replace "genkou", "01_���s" -replace "cloud", "02_�N���E�h")
    }

    create_directory $("$evidence_dir\�G�r�f���X\03_�R���y�A")
}

function search_latest_evidence_directorires {
    $function_dir_pattern = "^[A-Z]_[A-Z]{2}_[0-9]{4}_*"
    $function_dir = Get-ChildItem -Directory | Select-String -pattern $function_dir_pattern | Sort-Object -Descending LastWriteTime | Select-Object -First 1

    if ($function_dir -eq $null) {
        error "�G�r�f���X�i�[��f�B���N�g����������܂���B(�@�\ID_�@�\��)"
        read-host "[Enter]�L�[�ŏI�����܂��B"
        exit -1
    }

    $pattern_dir  = Get-ChildItem -Directory $function_dir | Sort-Object -Descending LastWriteTime | Select-Object -First 1
    if ($pattern_dir -eq $null) {
        error "�G�r�f���X�i�[��f�B���N�g����������܂���B(�@�\ID_�@�\��\�p�^�[���ԍ�\)"
        read-host "[Enter]�L�[�ŏI�����܂��B"
        exit -1
    }

    $genkou_dir = "$function_dir\$pattern_dir\�G�r�f���X\01_���s"
    if (!(test-path $genkou_dir)) {
        error "�G�r�f���X�i�[��f�B���N�g����������܂���B(���s = $genkou_dir)"
        read-host "[Enter]�L�[�ŏI�����܂��B"
        exit -1
    }

    $cloud_dir = "$function_dir\$pattern_dir\�G�r�f���X\02_�N���E�h"
    if (!(test-path $cloud_dir)) {
        error "�G�r�f���X�i�[��f�B���N�g����������܂���B(�N���E�h = $cloud_dir)"
        read-host "[Enter]�L�[�ŏI�����܂��B"
        exit -1
    }

    $dirs = New-Object System.Collections.Hashtable

    $dirs.add('genkou', $genkou_dir)
    $dirs.add('cloud',  $cloud_dir)

    return $dirs
}

function generate_elaplsed_times_html($function_id, $function_name, $pattern_no, $elapsed_time, $detail) {
    $header = @"
<html>
<head>
    <style type=""text/css"">
        body { font-family:""�l�r �S�V�b�N"", sans-serif; }
    </style>
</head>
<body>
"@
    
    $footer = @"
</body>
</html>
"@

    if ($elapsed_time.genkou.TotalSeconds -ne $null) {
        $diff_time = $elapsed_time.cloud.TotalSeconds - $elapsed_time.genkou.TotalSeconds
        $rate_time = [Math]::Abs([Math]::Truncate(($elapsed_time.cloud.TotalSeconds / $elapsed_time.genkou.TotalSeconds - 1) * 100))
    }
    else {
        $genkou_total_seconds = $elapsed_time.genkou.Hour * 3600 + $elapsed_time.genkou.Minute * 60 + $elapsed_time.genkou.Second
        $cloud_total_seconds  = $elapsed_time.cloud.Hour * 3600  + $elapsed_time.cloud.Minute * 60  + $elapsed_time.cloud.Second

        $diff_time = $cloud_total_seconds - $genkou_total_seconds
        $rate_time = [Math]::Abs([Math]::Truncate(($cloud_total_seconds / $genkou_total_seconds - 1) * 100))
    }
    
    $bgcolor = " bgcolor=""lightskyblue"""
    $time_message = "�N���E�h�̂ق��� $([Math]::Abs($diff_time)) �b ����"
    $rate_message = "�N���E�h�̂ق��� $rate_time % ����"

    if ($diff_time -gt 0){
        $bgcolor = " bgcolor=""red"""
        $time_message = "�N���E�h�̂ق��� $([Math]::Abs($diff_time)) �b �x��"
        $rate_message = "�N���E�h�̂ق��� $rate_time % �x��"    
    }
    elseif ($diff_time -eq 0) {
        $bgcolor = ""
        $time_message = "���s�ƃN���E�h�͕b�P�ʂœ����x"
        $rate_message = "���s�ƃN���E�h�͕b�P�ʂœ����x" 
    }

    $compare_table = @"
<table border=""1"">
    <thead>
        <th>�@�\ID</th>
        <th>�@�\��</th>
        <th>�e�X�g�p�^�[��No.</th>
        <th>���s��������</th>
        <th>�N���E�h��������</th>
        <th>�������ԍ���(�b)<br />�N���E�h - ���s</th>
        <th>����(�b)�R�����g<br />�N���E�h - ���s</th>
        <th>�x�����R�����g<br />�N���E�h / ���s</th>
    </thead>
    <tbody>
        <tr>
            <td>$($function_id)</td>
            <td>$($function_name)</td>
            <td align=""right"">$($pattern_no)</td>
            <td align=""center"">$($elapsed_time.genkou)</td>
            <td align=""center"">$($elapsed_time.cloud)</td>
            <td align=""right"" $bgcolor>$([Math]::Abs($diff_time))</td>
            <td$($bgcolor)>$($time_message)</td>
            <td$($bgcolor)>$($rate_message)</td>
        </tr>
    </tbody>
</table>
"@

    if ($detail_table -ne $null) {
        $detail_table = @"
<table border=""1"">
    <thead>
        <th>��</th>
        $(foreach($prop in $($detail.genkou | Get-Member -MemberType NoteProperty)){
            "<th>$($prop.Name)</th>`n"
        })
    </thead>
    <tbody>
        <tr>
            <td>���s</td>
            $(foreach($prop in $($detail.genkou | Get-Member -MemberType NoteProperty)){
                "<td>$($detail.genkou.$($prop.Name))</td>`n"
            })
        </tr>
        <tr>
            <td>�N���E�h</td>
            $(foreach($prop in $($detail.cloud | Get-Member -MemberType NoteProperty)){
                "<td>$($detail.cloud.$($prop.Name))</td>`n"
            })
        </tr>
    </tbody>
</table>
"@
    }

    $html = $header
    $html += $compare_table

    if ($detail_table -ne $null) {
        $html += "<br />"
        $html += $detail_table
    }
    $html += $footer

    return $html
}