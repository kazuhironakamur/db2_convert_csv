$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\�R���y�A�c�[��\�R���y�A�`�F�b�N�\�쐬�c�[���c�k_�c��r��_���C10.xlsm"

$Host.ui.RawUI.WindowTitle = "�������Ԕ�r URL�ɋN��ID���܂܂�Ă��Ȃ��ꍇ�Ɏg�p"

$function_id = $null

$function_id = read_function_id $function_id
$function_name = get_function_name $function_id
Write-Host "�w�肳�ꂽ�@�\ID�̋@�\���� �y $function_name �z �ł��B"

$pattern_no = read_pattern_no
Write-Host "�p�^�[���ԍ��� �y $pattern_no �z ���g�p���܂��B"

create_evidence_directories $function_id $function_name $pattern_no

$today = get-date -format "yyyy-MM-dd"
$timestamps = New-Object System.Collections.Hashtable

foreach ($env in @('genkou', 'cloud')) {
    while ($true) {
        $msg = $($env -replace 'genkou', '���s' -replace 'cloud', '�N���E�h') + "�̎���������͂��Ă������� "
        $t = $t.trim()
        $t = Read-Host $msg

        if ($t -match "^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$") {
            $timestamps.add($env, $t)
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
$was_log = New-Object System.Collections.Hashtable
$headers = @("srdate", "sttime", "edtime", "srtime", "userid", "wstmid", "actnm", "mtdnm", "resurl")

foreach($env in @('genkou', 'cloud')) {
        $query = @"
select $($headers -join ",")
from fctlsp00
where userid = '$($settings.$env.user_id)'
and wstmid = '$($settings.$env.session_id)'
and edtime >= '$today $($timestamps.$env)'
order by sttime asc
fetch first 1 rows only
"@

    $et = execute_query $query $env $headers
    $was_log.add($env, $et)
}

if ($was_log.genkou.actnm -ne $was_log.cloud.actnm) {
    Write-Host -ForegroundColor Red "ERROR: WAS���O���(FCTLSP00)��ACTNM���A���s/�N���E�h�ňقȂ��Ă��܂��B"
    Write-Host -ForegroundColor Red "ERROR: �قȂ郍�O�̔�r�́A���̃c�[���ł̓T�|�[�g����Ă��܂���B"
    Write-Host -ForegroundColor Red "ERROR: �e�X�g���Ď��s���Ă��������B"
    Write-Host "���s�V�X�e����ACTNM    : $($was_log.genkou.actnm)"
    Write-Host "�N���E�h�V�X�e����ACTNM: $($was_log.cloud.actnm)"
    read-host "�G���[���e���m�F���Ă��������B[Enter]�L�[�ŏI��"
    exit -1
}

$elapsed_time = New-Object System.Collections.Hashtable

foreach ($env in @("genkou", "cloud")) {
    $tm = $was_log.$env.sttime -replace "\.", ":"
    $start_time = $tm.remove(19, 7).remove(0, 11)

    $tm = $was_log.$env.edtime -replace "\.", ":"
    $end_time   = $tm.remove(19, 7).remove(0, 11)
    
    $e = get-date $end_time
    $s = get-date $start_time
    $elapsed_time.add($env, $e - $s)
}

$diff_time = [Math]::Abs($elapsed_time.cloud.TotalSeconds - $elapsed_time.genkou.TotalSeconds)
$rate_time = [Math]::Abs([Math]::Truncate(($elapsed_time.cloud.TotalSeconds / $elapsed_time.genkou.TotalSeconds - 1) * 100))

$bgcolor = " bgcolor=""lightskyblue"""
$time_message = "�N���E�h�̂ق��� $diff_time �b ����"
$rate_message = "�N���E�h�̂ق��� $rate_time % ����"
if ($elapsed_time.cloud.TotalSeconds -gt $elapsed_time.genkou.TotalSeconds){
    $bgcolor = " bgcolor=""red"""
    $time_message = "�N���E�h�̂ق��� $diff_time �b �x��"
    $rate_message = "�N���E�h�̂ق��� $rate_time % �x��"
}
elseif ($elapsed_time.cloud.TotalSeconds -eq $elapsed_time.genkou.TotalSeconds) {
    $bgcolor = ""
    $time_message = "���s�ƃN���E�h�͕b�P�ʂœ����x"
    $rate_message = "���s�ƃN���E�h�͕b�P�ʂœ����x" 
}

    "<html>
<head>
    <style type=""text/css"">
        body { font-family:""�l�r �S�V�b�N"", sans-serif; }
    </style>
</head>
<body>
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
                <td align=""right"" $bgcolor>$($diff_time)</td>
                <td$($bgcolor)>$($time_message)</td>
                <td$($bgcolor)>$($rate_message)</td>
            </tr>
        </tbody>
    </table>
    <br />
    <table border=""1"">
        <thead>
            <th>��</th>
            <th>srdate</th>
            <th>sttime</th>
            <th>edtime</th>
            <th>srtime</th>
            <th>userid</th>
            <th>wstmid</th>
            <th>actnm</th>
            <th>mtdnm</th>
            <th>resurl</th>
        </thead>
        <tbody>
            <tr>
                <td>���s</td>
                <td>$($was_log.genkou.srdate)</td>
                <td>$($was_log.genkou.sttime)</td>
                <td>$($was_log.genkou.edtime)</td>
                <td>$($was_log.genkou.srtime)</td>
                <td>$($was_log.genkou.userid)</td>
                <td>$($was_log.genkou.wstmid)</td>
                <td>$($was_log.genkou.actnm)</td>
                <td>$($was_log.genkou.mtdnm)</td>
                <td>$($was_log.genkou.resurl)</td>
            </tr>
            <tr>
                <td>�N���E�h</td>
                <td>$($was_log.cloud.srdate)</td>
                <td>$($was_log.cloud.sttime)</td>
                <td>$($was_log.cloud.edtime)</td>
                <td>$($was_log.cloud.srtime)</td>
                <td>$($was_log.cloud.userid)</td>
                <td>$($was_log.cloud.wstmid)</td>
                <td>$($was_log.cloud.actnm)</td>
                <td>$($was_log.cloud.mtdnm)</td>
                <td>$($was_log.cloud.resurl)</td>
            </tr>
        </tbody>
    </table>
</body>
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\�G�r�f���X\$($pattern_no)_�������Ԕ�r.html"

info "�s�v�Ȉꎞ�t�@�C�����폜���܂��B"
remove-item temporary*

info "�������I�����܂����B"
info "��������.html�t�@�C�����m�F���Ă��������B[Enter]�L�[�ŏI��"
read-host
