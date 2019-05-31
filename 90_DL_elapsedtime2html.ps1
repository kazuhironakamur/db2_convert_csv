$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$Host.ui.RawUI.WindowTitle = "DL�n �������Ԕ�r"

$function_id = $null

$function_id = read_function_id $function_id
$function_name = get_function_name $function_id
Write-Host "�w�肳�ꂽ�@�\ID�̋@�\���� �y $function_name �z �ł��B"

$pattern_no = read_pattern_no
Write-Host "�p�^�[���ԍ��� �y $pattern_no �z ���g�p���܂��B"

create_evidence_directories $function_id $function_name $pattern_no

$today = get-date -format "yyyy-MM-dd"
$input_times = New-Object System.Collections.Hashtable

foreach ($env in @('genkou', 'cloud')) {
    while ($true) {
        $msg = $($env -replace 'genkou', '���s' -replace 'cloud', '�N���E�h') + "�̎���������͂��Ă������� "
        $t = Read-Host $msg
        $t = $t.trim()
        $t = $t -replace '\(','' -replace '\)',''

        if ($t -match "^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$") {
            $input_times.add($env, $t)
            break
        }
        else {
            error "���͂��ꂽ����������������܂���B"
        }
    }
}

##########################################################################
info "�������Ԃ��r���܂�"
##########################################################################

$elapsed_time = New-Object System.Collections.Hashtable

foreach ($env in @("genkou", "cloud")) {
    $t = get-date $input_times.$env
    $elapsed_time.add($env, $t)
}

$html = generate_elaplsed_times_html $function_id $function_name $pattern_no $elapsed_time $null
$html | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\�G�r�f���X\$($pattern_no)_�������Ԕ�r.html"

info "�������I�����܂����B[Enter]�L�[�ŏI��"
read-host