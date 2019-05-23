$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\�R���y�A�c�[��\�R���y�A�`�F�b�N�\�쐬�c�[���c�k_�c��r��_���C10.xlsm"

$Host.ui.RawUI.WindowTitle = "WORK�e�[�u���o�͗p"

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
    info "WORK�e�[�u���o�͏������J�n���܂��B"
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
    info "�t�@�C���쐬�w���ԍ����̎悵�܂��B"
    ##########################################################################
    $headers = @("flssno", "flssoyano", "knmsid", "epcd", "epkrcd", "tc", "usrprl", "fltp",
        "ssjkb", "jkrvl", "tkkdjtime", "kickpgkb", "kickpgnm", "dspsrnm", "dspkeynm1",
        "dspkeyvl1", "dspkeynm2", "dspkeyvl2", "prtprm1", "prtprm2", "csvclm1", "csvclm2",
        "csvclm3", "csvclm4", "csvclm5", "prm01", "prm02", "flsrsts", "sijidate", "sijitime",
        "strdate", "strtime", "enddate", "endtime", "dwldate", "dwltime", "flpath", "fldspnm",
        "fldlplndate", "fldlenddate", "fldlendtime", "bcksdc", "bcksju", "bcktbg", "bckpid", "delkb",
        "addy__", "addb__", "adid__", "awid__", "atcd__", "ausr__", "updy__", "uptb__", "upid__", "uwid__", "utcd__", "uusr__")

    $time = New-Object System.Collections.Hashtable
    $elapsed_time = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
select * from fmmljp00
where csvclm1 = '$table_name'
and ausr__ = '$($settings.$env.user_id)'
and awid__ = '$($settings.$env.session_id)'
order by addy__ desc, addb__ desc
fetch first 1 rows only
"@

        $fmmljp00 = execute_query $query $env $headers

        if ($settings.$env.ContainsKey("flssno")) { $settings.$env.Remove("flssno") }

        $settings.$env.add("flssno", $($fmmljp00.flssno))
    
        $read_env = $env -replace "genkou", "���s" -replace "cloud", "�N���E�h"
        write-host "�ǂݎ�����t�@�C���쐬�w���ԍ�: ��: $read_env �t�@�C���쐬�w���ԍ�: $($fmmljp00.flssno)"

        $time.add($env, $fmmljp00)

        # �������Ԑ��`
        if ($time.$env.strtime -eq "") { $start_time = $time.$env.bcksju  -replace "\.", ":" }
        else                           { $start_time = $time.$env.strtime -replace "\.", ":" }
        $end_time =                                    $time.$env.endtime -replace "\.", ":"

        # �������Ԍv�Z
        $elapsed_time.add($env, (get-date $end_time) - (get-date $start_time))
    }

    ##########################################################################
    info "�Ώۃe�[�u�������L�[�𒊏o���܂��B"
    ##########################################################################
    # ���s/�N���E�h�Ńe�[�u����`�ɍ��ق͂Ȃ��O��Ȃ̂Ō��s����̂ݎ擾����
    $env = 'genkou'
    $query = @"
select colname from syscat.keycoluse where tabname = '$table_name'
order by colseq
"@

    # ���o������L�[��CSV����ǂݍ����arraylist�����Aorder by��Ŏg�p����
    $p_keys = execute_query $query $env @("COLNAME")
    $order_keys = New-Object System.Collections.ArrayList
    foreach ($p in $p_keys) { $order_keys.add($p.COLNAME) | out-null }

    ##########################################################################
    info "�Ώۃe�[�u�������𒊏o���܂��B"
    ##########################################################################
    # ���s/�N���E�h�Ńe�[�u����`�ɍ��ق͂Ȃ��O��Ȃ̂Ō��s����̂ݎ擾����
    $env = 'genkou'
    $query = @"
SELECT COLNAME
FROM syscat.columns
WHERE tabschema=(select current_schema from dual)
AND tabname='$table_name'
ORDER BY COLNO
"@

    # ���o�������CSV����ǂݍ����arraylist�����A�w�b�_�[�s�Ƃ��Ďg�p����
    $cols = execute_query $query $env @("COLNAME")
    $file_headers = New-Object System.Collections.ArrayList
    foreach ($c in $cols) { $file_headers.add($c.COLNAME) | out-null }

    ##########################################################################
    info "�Ώۃe�[�u����CSV�����܂��B"
    ##########################################################################
    $output_file_path = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
SELECT * FROM $table_name WHERE flssno = '$($settings.$env.flssno)'
ORDER BY $($order_keys -join ",")
"@

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
    info "�������Ԃ��r���܂�"
    ##########################################################################

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
            <th>flssno</th>
            <th>flssoyano</th>
            <th>knmsid</th>
            <th>kickpgnm</th>
            <th>dspsrnm</th>
            <th>csvclm1</th>
            <th>csvvlm5</th>
            <th>sijidate</th>
            <th>sijitime</th>
            <th>strdate</th>
            <th>strtime</th>
            <th>enddate</th>
            <th>endtime</th>
            <th>fldspnm</th>
        </thead>
        <tbody>
            <tr>
                <td>���s</td>
                <td>$($time.genkou.flssno)</td>
                <td>$($time.genkou.flssoyano)</td>
                <td>$($time.genkou.knmsid)</td>
                <td>$($time.genkou.kickpgnm)</td>
                <td>$($time.genkou.dspsrnm)</td>
                <td>$($time.genkou.csvclm1)</td>
                <td>$($time.genkou.csvvlm5)</td>
                <td>$($time.genkou.sijidate)</td>
                <td>$($time.genkou.sijitime)</td>
                <td>$($time.genkou.strdate)</td>
                <td>$($time.genkou.strtime)</td>
                <td>$($time.genkou.enddate)</td>
                <td>$($time.genkou.endtime)</td>
                <td>$($time.genkou.fldspnm)</td>
            </tr>
            <tr>
                <td>�N���E�h</td>
                <td>$($time.cloud.flssno)</td>
                <td>$($time.cloud.flssoyano)</td>
                <td>$($time.cloud.knmsid)</td>
                <td>$($time.cloud.kickpgnm)</td>
                <td>$($time.cloud.dspsrnm)</td>
                <td>$($time.cloud.csvclm1)</td>
                <td>$($time.cloud.csvvlm5)</td>
                <td>$($time.cloud.sijidate)</td>
                <td>$($time.cloud.sijitime)</td>
                <td>$($time.cloud.strdate)</td>
                <td>$($time.cloud.strtime)</td>
                <td>$($time.cloud.enddate)</td>
                <td>$($time.cloud.endtime)</td>
                <td>$($time.cloud.fldspnm)</td>
            </tr>
        </tbody>
    </table>
</body>
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)_�������Ԕ�r_$($table_name).html"

    info "�s�v�Ȉꎞ�t�@�C�����폜���܂��B"
    remove-item temporary*

    info "�������I�����܂����B"
    info "�쐬���ꂽ�f�[�^�Ə�������.html�t�@�C�����m�F���Ă��������B"
    info "�I������ꍇ�́ACtrl+Enter���������Ă��������B"
}