$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\�R���y�A�c�[��\�R���y�A�`�F�b�N�\�쐬�c�[���c�k_�c��r��_���C10.xlsm"

$Host.ui.RawUI.WindowTitle = "�e�[�u���o�͗p"

$function_id = $null

while ($true) {
    ##########################################################################
    info "�e�[�u�������������J�n���܂��B"
    ##########################################################################
    while ($true) {
        $found_tables = read_table_remarks

        if ($found_tables -eq "") { break }

        $found_tables | format-table -AutoSize -Property type, name, remarks

        info "�����������I�����܂����B"
        info "�Ώۃe�[�u���̏�񂪊m�F�ł��A���̏����ɐi�ޏꍇ�́A�e�[�u��������͂�����[Enter]�L�[���������Ă��������B"
    }

    ##########################################################################
    info "�e�[�u���o�͏������J�n���܂��B"
    ##########################################################################
    $table_name = read_table_name
    $table_display_name = get_table_display_name $table_name
    Write-Host "�w�肳�ꂽ�e�[�u���̃e�[�u������ �y $table_display_name �z �ł��B"

    $function_id = read_function_id $function_id
    $function_name = get_function_name $function_id
    Write-Host "�w�肳�ꂽ�@�\ID�̋@�\���� �y $function_name �z �ł��B"

    $pattern_no = read_pattern_no
    Write-Host "�p�^�[���ԍ��� �y $pattern_no �z ���g�p���܂��B"

    create_evidence_directories $function_id $function_name $pattern_no

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
    $compare_target_files = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
select * from $table_name where ausr__ = '$($timestamps.$env.user_id)' and awid__ = '$($timestamps.$env.session_id)' 
and addy__ = '$($timestamps.$env.insert_date)' and addb__ = '$($timestamps.$env.insert_time)'
"@

        if ($order_keys.length -gt 0) { $query += "`norder by $($order_keys -join ",")" }

        $dump = execute_query $query $env $file_headers

        # �ŏI�I��CSV�t�@�C�����쐬����
        $evidence_dir = "$($function_id)_$($function_name)\$($pattern_no)\"
        $work_dir = "$($evidence_dir)\WORK\$env" -replace "genkou", "���s" -replace "cloud", "�N���E�h"

        $compare_target_file = "$($work_dir)\$($pattern_no)_$($table_name).csv"

        $compare_target_files.add($env, $compare_target_file)

        $dump | Export-Csv $compare_target_file -Encoding Default -NoTypeInformation
    }

    ##########################################################################
    info "�R���y�A�c�[�������s���܂��B"
    ##########################################################################
    $e = New-Object PSExcel

    $compare_tool_full_path = Convert-Path $compare_tool_path

    $template_full_path = "$(Split-Path -Parent $compare_tool_full_path)\00_�_�E�����[�h_�R���y�A�`�F�b�N�\_�e���v���[�g_�c��r.xlsx"
    
    $compare_target_genkou_file_full_path = Convert-Path ".\$($compare_target_files.genkou)"
    $compare_target_cloud_file_full_path  = Convert-Path ".\$($compare_target_files.cloud)"

    $output_result_full_path = "$(Convert-Path $evidence_dir)�G�r�f���X\03_�R���y�A"

    if ($(test-path -PathType Container $output_result_full_path) -eq $False) { new-item -ItemType Directory $output_result_full_path | out-null }

    try {
        if ($e.Open($compare_tool_full_path)) {
            $e.SetValue(3,  2, $template_full_path)                         | Out-Null
            $e.SetValue(5,  2, $compare_target_genkou_file_full_path)       | Out-Null
            $e.SetValue(7,  2, $compare_target_cloud_file_full_path)        | Out-Null
            $e.SetValue(9,  2, $output_result_full_path)                    | Out-Null
            $e.SetValue(10, 2, "$($pattern_no)_��r����_$($table_name)")    | Out-Null
            $e.SetValue(11, 2, "0")                                         | Out-Null

            if ($e.PressButton('�R���y�A���s')) {
                info "�R���y�A���I�����܂����B"
            }
            else {
                error "�R���y�A�Ɏ��s���܂����B"
                exit -1
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
and resurl like '/$($function_id_for_query_string)%'
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

    $html = generate_elaplsed_times_html $function_id $function_name $pattern_no $elapsed_time $was_log
    $html | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\�G�r�f���X\$($pattern_no)_�������Ԕ�r.html"

    info "�������I�����܂����B"
    info "�쐬���ꂽ�f�[�^�Ə�������.html�t�@�C�����m�F���Ă��������B"
    info "�I������ꍇ�́ACtrl+Enter���������Ă��������B"
}