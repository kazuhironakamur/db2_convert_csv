$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\�R���y�A�c�[��\�R���y�A�`�F�b�N�\�쐬�c�[���c�k_�c��r��_���C10.xlsm"

$Host.ui.RawUI.WindowTitle = "�e�[�u���o�͗p"

while ($true) {
    ##########################################################################
    info "�e�[�u�������������J�n���܂��B"
    ##########################################################################
    while ($true) {
        $found_tables = read_table_remarks

        if ($found_tables -eq "") { break }

        $found_tables | format-table -AutoSize -Property type, name, remarks

        info "�����������I�����܂����B"
        info "�I������ꍇ�́A�e�[�u��������͂�����[Enter]�L�[���������Ă��������B"
    }

    ##########################################################################
    info "�e�[�u���o�͏������J�n���܂��B"
    ##########################################################################
    $table_name = read_table_name
    $table_display_name = get_table_display_name $table_name
    Write-Host "�w�肳�ꂽ�e�[�u���̃e�[�u������ �y $table_display_name �z �ł��B"

    $function_id = read_function_id
    $function_name = get_function_name $function_id
    Write-Host "�w�肳�ꂽ�@�\ID�̋@�\���� �y $function_name �z �ł��B"

    $pattern_no = read_pattern_no
    Write-Host "�p�^�[���ԍ��� �y $pattern_no �z ���g�p���܂��B"

    ##########################################################################
    info "�Ώۃe�[�u���̒��߃^�C���X�^���v�擾���܂��B"
    ##########################################################################
    # �����Ainsert��update�Œ��o����f�[�^��ύX���悤���ƍl���܂������A
    # update�̃^�C���X�^���v�̓g�����U�N�V�������œ��ꂳ��Ȃ����Ƃ��킩��܂����B
    # ��)
    # 1�`�[�̓o�^�ŁA���׍s�̃^�C���X�^���v�̓o���o���ɂȂ��Ă��܂��܂��B
    # �Ȃ̂ŁA���ׂ�insert���̃^�C���X�^���v�Œ��o����悤�ɕύX���܂����B
    # �X�V�f�[�^�́A�o�^�f�[�^�̈ꕔ�Ȃ̂őΏۍs�Ƃ��đS�̂���Ղł��܂��B

    $timestamps = New-Object System.Collections.Hashtable
    $headers = @("user_id", "session_id", "insert_date", "insert_time")

    foreach($env in @('genkou', 'cloud')) {
        $query = @"
select distinct ausr__, awid__, addy__, addb__
from $table_name
where ausr__ = '$($settings.$env.user_id)'
and   awid__ = '$($settings.$env.session_id)'
and   addy__ = current date
order by addy__ desc, addb__ desc
fetch first 1 rows only
"@

        $ts = execute_query $query $env $headers

        $timestamps.add($env, $ts)

        $dt = $timestamps.$env.insert_date
        $timestamps.$env.insert_date = "$($dt.substring(0, 4))-$($dt.substring(4, 2))-$($dt.substring(6, 2))"
    
        $timestamps.$env.insert_time = $timestamps.$env.insert_time -replace "\.", ":"
    }

    Write-Host "�� ���s�V�X�e�� �^�C���X�^���v"
    Write-Host "���[�U�[ID  : $($timestamps.genkou.user_id)"
    Write-Host "�Z�b�V����ID: $($timestamps.genkou.session_id)"
    Write-Host "�o�^���t    : $($timestamps.genkou.insert_date)"
    Write-Host "�o�^����    : $($timestamps.genkou.insert_time)"
    Write-Host ""
    Write-Host "���N���E�h�V�X�e�� �^�C���X�^���v"
    Write-Host "���[�U�[ID  : $($timestamps.cloud.user_id)"
    Write-Host "�Z�b�V����ID: $($timestamps.cloud.session_id)"
    Write-Host "�o�^���t    : $($timestamps.cloud.insert_date)"
    Write-Host "�o�^����    : $($timestamps.cloud.insert_time)"

    ##########################################################################
    info "�Ώۃe�[�u�������L�[�𒊏o���܂��B"
    ##########################################################################
    # ���s/�N���E�h�Ńe�[�u����`�ɍ��ق͂Ȃ��O��Ȃ̂Ō��s����̂ݎ擾����
    $env = 'genkou'
    $query = @"
select colname from syscat.keycoluse where tabname = '$table_name'
order by colseq
"@

    # ���o������L�[��arraylist�����Aorder by��Ŏg�p����
    $p_keys = execute_query $query $env @("COLNAME")
    $order_keys = New-Object System.Collections.ArrayList
    foreach ($p in $p_keys) { $order_keys.add($p.COLNAME) | out-null }


    ##########################################################################
    info "�Ώۃe�[�u�������𒊏o���܂��B"
    ##########################################################################
    # ���s/�N���E�h�Ńe�[�u����`�ɍ��ق͂Ȃ��O��Ȃ̂Ō��s����̂ݎ擾����
    $env = 'genkou'
    $query = @"
select colname
from syscat.columns
where tabschema=(select current_schema from dual)
and tabname='$table_name'
order by colno
"@

    # ���o�������arraylist�����A�w�b�_�[�s�Ƃ��Ďg�p����
    $cols = execute_query $query $env @("COLNAME")
    $file_headers = New-Object System.Collections.ArrayList
    foreach ($c in $cols) { $file_headers.add($c.COLNAME) | out-null }


    ##########################################################################
    info "�Ώۃe�[�u����CSV�����܂��B"
    ##########################################################################
    $output_file_path = New-Object System.Collections.Hashtable

    foreach($env in @('genkou', 'cloud')) {
        $query = @"
select * from $table_name where ausr__ = '$($timestamps.$env.user_id)' and awid__ = '$($timestamps.$env.session_id)' 
and addy__ = '$($timestamps.$env.insert_date)' and addb__ = '$($timestamps.$env.insert_time)'
"@

        if ($order_keys.length -gt 0) { $query += "`norder by $($order_keys -join ",")" }

        $dump = execute_query $query $env $file_headers

        # �ŏI�I��CSV�t�@�C�����쐬����
        $function_dir = "$($function_id)_$($function_name)"
        if ($(test-path -PathType Container $function_dir) -eq $False) { new-item -ItemType Directory $function_dir | out-null }

        $directory_name = "$function_dir\$env" -replace "genkou", "���s" -replace "cloud", "�N���E�h"
        if ($(test-path -PathType Container $directory_name) -eq $False) { new-item -ItemType Directory $directory_name | out-null }

        $output_file = "$($directory_name)\$($pattern_no)_$($table_name).csv"

        $output_file_path.add($env, $output_file)

        $dump | Export-Csv $output_file -Encoding Default -NoTypeInformation
    }

    ##########################################################################
    info "�R���y�A�c�[�������s���܂��B"
    ##########################################################################
    $e = New-Object PSExcel

    $compare_tool_full_path = Convert-Path $compare_tool_path

    $template_full_path = "$(Split-Path -Parent $compare_tool_full_path)\00_�_�E�����[�h_�R���y�A�`�F�b�N�\_�e���v���[�g_�c��r.xlsx"
    
    $input_genkou_file_full_path = Convert-Path ".\$($output_file_path.genkou)"
    $input_cloud_file_full_path  = Convert-Path ".\$($output_file_path.cloud)"

    $output_result_full_path = "$(Split-Path -Parent $input_genkou_file_full_path | Split-Path -Parent)\�R���y�A"

    if ($(test-path -PathType Container $output_result_full_path) -eq $False) { new-item -ItemType Directory $output_result_full_path | out-null }

    try {
        if ($e.Open($compare_tool_full_path)) {
            $e.SetValue(3,  2, $template_full_path)                         | Out-Null
            $e.SetValue(5,  2, $input_genkou_file_full_path)                | Out-Null
            $e.SetValue(7,  2, $input_cloud_file_full_path)                 | Out-Null
            $e.SetValue(9,  2, $output_result_full_path)                    | Out-Null
            $e.SetValue(10, 2, "$($pattern_no)_��r����_$($table_name)")    | Out-Null
            $e.SetValue(11, 2, "0")                                         | Out-Null

            if ($e.PressButton('�R���y�A���s')) {
                info "�R���y�A���I�����܂����B"
            }
            else {
                error "�R���y�A�Ɏ��s���܂����B"
                
            }
        }
    }
    catch {
        read-host "�G���[���e���m�F���Ă��������B[Enter]�L�[�ŏI��"
    }
    finally{
        $e.Quit()
    }

    ##########################################################################
    info "WAS���O���珈�����ԏ����v�����܂��B"
    ##########################################################################
    $was_log = New-Object System.Collections.Hashtable
    $headers = @("srdate", "sttime", "edtime", "srtime", "userid", "wstmid", "actnm", "mtdnm", "resurl")
    $function_id_for_query_string = $function_id.trim().ToLower() -replace "_", ""

    foreach($env in @('genkou', 'cloud')) {
        $query = @"
select $($headers -join ",")
from fctlsp00
where userid = '$($settings.$env.user_id)'
and wstmid = '$($settings.$env.session_id)'
and mtdnm = 'ent'
and resurl like '/$($function_id_for_query_string)%?redirect=true'
order by sttime desc
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
<body>
    <table border=""1"">
        <thead>
            <th>���s��������</th>
            <th>�N���E�h��������</th>
            <th>����(�b)<br />�N���E�h - ���s</th>
            <th>�x����<br />�N���E�h / ���s</th>
        </thead>
        <tbody>
            <tr>
                <td align=""center"">$($elapsed_time.genkou)</td>
                <td align=""center"">$($elapsed_time.cloud)</td>
                <td align=""right"" $bgcolor>$($time_message)</td>
                <td align=""right"" $bgcolor>$($rate_message)</td>
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
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)_�������Ԕ�r.html"

    info "�s�v�Ȉꎞ�t�@�C�����폜���܂��B"
    remove-item temporary*

    info "�������I�����܂����B"
    info "�쐬���ꂽ�f�[�^�Ə�������.html�t�@�C�����m�F���Ă��������B"
    info "�I������ꍇ�́ACtrl+Enter���������Ă��������B"
}