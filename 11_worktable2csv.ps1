$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\コンペアツール\コンペアチェック表作成ツールＤＬ_縦比較版_改修10.xlsm"

$Host.ui.RawUI.WindowTitle = "WORKテーブル出力用"

$function_id = $null

while ($true) {
    ##########################################################################
    info "テーブル検索処理を開始します。"
    ##########################################################################
    while ($true) {
        $found_tables = read_table_remarks

        if ($found_tables -eq "") { break }

        $found_tables | format-table -AutoSize -Property type, name, remarks

        info "検索処理が終了しました。"
        info "対象テーブルの情報が確認でき、次の処理に進む場合は、テーブル名を入力せずに[Enter]キーを押下してください。"
    }

    ##########################################################################
    info "WORKテーブル出力処理を開始します。"
    ##########################################################################
    $table_name = read_table_name
    $table_display_name = get_table_display_name $table_name
    Write-Host "指定されたテーブルのテーブル名は 【 $table_display_name 】 です。"

    $function_id = read_function_id $function_id
    $function_name = get_function_name $function_id
    Write-Host "指定された機能IDの機能名は 【 $function_name 】 です。"

    $pattern_no = read_pattern_no
    Write-Host "パターン番号は 【 $pattern_no 】 を使用します。"

    create_evidence_directories $function_id $function_name $pattern_no

    ##########################################################################
    info "ファイル作成指示番号を採取します。"
    ##########################################################################
    $headers = @("flssno", "flssoyano", "knmsid", "epcd", "epkrcd", "tc", "usrprl", "fltp",
        "ssjkb", "jkrvl", "tkkdjtime", "kickpgkb", "kickpgnm", "dspsrnm", "dspkeynm1",
        "dspkeyvl1", "dspkeynm2", "dspkeyvl2", "prtprm1", "prtprm2", "csvclm1", "csvclm2",
        "csvclm3", "csvclm4", "csvclm5", "prm01", "prm02", "flsrsts", "sijidate", "sijitime",
        "strdate", "strtime", "enddate", "endtime", "dwldate", "dwltime", "flpath", "fldspnm",
        "fldlplndate", "fldlenddate", "fldlendtime", "bcksdc", "bcksju", "bcktbg", "bckpid", "delkb",
        "addy__", "addb__", "adid__", "awid__", "atcd__", "ausr__", "updy__", "uptb__", "upid__", "uwid__", "utcd__", "uusr__")

    $headers = @(
        "flssno", "flssoyano", "knmsid", "kickpgnm", "dspsrnm", "csvclm1", "csvvlm5", "sijidate", "sijitime", "strdate", "strtime", "enddate", "endtime", "fldspnm", "bcksju", "uptb__"
    )

    $time = New-Object System.Collections.Hashtable
    $elapsed_time = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
select $($headers -join ",") from fmmljp00
where csvclm1 = '$table_name'
and ausr__ = '$($settings.$env.user_id)'
and awid__ = '$($settings.$env.session_id)'
order by addy__ desc, addb__ desc
fetch first 1 rows only
"@

        $fmmljp00 = execute_query $query $env $headers

        if ($settings.$env.ContainsKey("flssno")) { $settings.$env.Remove("flssno") }

        $settings.$env.add("flssno", $($fmmljp00.flssno))
    
        $read_env = $env -replace "genkou", "現行" -replace "cloud", "クラウド"
        write-host "読み取ったファイル作成指示番号: 環境: $read_env ファイル作成指示番号: $($fmmljp00.flssno)"

        $time.add($env, $fmmljp00)

        $time.$env

        # 処理時間整形
        if ($time.$env.strtime -eq "") { $start_time = $time.$env.bcksju  -replace "\.", ":" }
        else                           { $start_time = $time.$env.strtime -replace "\.", ":" }
        
        if ($time.$env.endtime -eq "") { $end_time = $time.$env.uptb__  -replace "\.", ":" }
        else                           { $end_time = $time.$env.endtime -replace "\.", ":" }

        # 処理時間計算
        $elapsed_time.add($env, (get-date $end_time) - (get-date $start_time))
    }

    ##########################################################################
    info "対象テーブルから主キーを抽出します。"
    ##########################################################################
    # 現行/クラウドでテーブル定義に差異はない前提なので現行からのみ取得する
    $env = 'genkou'
    $query = @"
select colname from syscat.keycoluse where tabname = '$table_name'
order by colseq
"@

    # 抽出した主キーをCSVから読み込んでarraylist化し、order by句で使用する
    $p_keys = execute_query $query $env @("COLNAME")
    $order_keys = New-Object System.Collections.ArrayList
    foreach ($p in $p_keys) { $order_keys.add($p.COLNAME) | out-null }

    ##########################################################################
    info "対象テーブルから列を抽出します。"
    ##########################################################################
    # 現行/クラウドでテーブル定義に差異はない前提なので現行からのみ取得する
    $env = 'genkou'
    $query = @"
SELECT COLNAME
FROM syscat.columns
WHERE tabschema=(select current_schema from dual)
AND tabname='$table_name'
ORDER BY COLNO
"@

    # 抽出した列をCSVから読み込んでarraylist化し、ヘッダー行として使用する
    $cols = execute_query $query $env @("COLNAME")
    $file_headers = New-Object System.Collections.ArrayList
    foreach ($c in $cols) { $file_headers.add($c.COLNAME) | out-null }

    ##########################################################################
    info "対象テーブルをCSV化します。"
    ##########################################################################
    $compare_target_files = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
SELECT * FROM $table_name WHERE flssno = '$($settings.$env.flssno)'
"@
        
        if ($order_keys.length -gt 0) { $query += "`norder by $($order_keys -join ",")" }

        $dump = execute_query $query $env $file_headers

        # 最終的なCSVファイルを作成する
        $evidence_dir = "$($function_id)_$($function_name)\$($pattern_no)\"
        $work_dir = "$($evidence_dir)\WORK\$env" -replace "genkou", "現行" -replace "cloud", "クラウド"

        $compare_target_file = "$($work_dir)\$($pattern_no)_$($table_name).csv"

        $compare_target_files.add($env, $compare_target_file)

        $dump | Export-Csv $compare_target_file -Encoding Default -NoTypeInformation
    }

    ##########################################################################
    info "コンペアツールを実行します。"
    ##########################################################################
    $e = New-Object PSExcel

    $compare_tool_full_path = Convert-Path $compare_tool_path

    $template_full_path = "$(Split-Path -Parent $compare_tool_full_path)\00_ダウンロード_コンペアチェック表_テンプレート_縦比較.xlsx"
    
    $compare_target_genkou_file_full_path = Convert-Path ".\$($compare_target_files.genkou)"
    $compare_target_cloud_file_full_path  = Convert-Path ".\$($compare_target_files.cloud)"

    $output_result_full_path = "$(Convert-Path $evidence_dir)エビデンス\03_コンペア"

    if ($(test-path -PathType Container $output_result_full_path) -eq $False) { new-item -ItemType Directory $output_result_full_path | out-null }

    try {
        if ($e.Open($compare_tool_full_path)) {
            $e.SetValue(3,  2, $template_full_path)                         | Out-Null
            $e.SetValue(5,  2, $compare_target_genkou_file_full_path)       | Out-Null
            $e.SetValue(7,  2, $compare_target_cloud_file_full_path)        | Out-Null
            $e.SetValue(9,  2, $output_result_full_path)                    | Out-Null
            $e.SetValue(10, 2, "$($pattern_no)_比較結果_$($table_name)")    | Out-Null
            $e.SetValue(11, 2, "0")                                         | Out-Null

            if ($e.PressButton('コンペア実行')) {
                info "コンペアが終了しました。"
            }
            else {
                error "コンペアに失敗しました。"
                exit -1
            }
        }
    }
    catch {
        read-host "エラー内容を確認してください。[Enter]キーで終了"
    }
    finally{
        $e.Quit()
    }

    ##########################################################################
    info "処理時間を比較します"
    ##########################################################################
    $html = generate_elaplsed_times_html $function_id $function_name $pattern_no $elapsed_time $time
    $html | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\エビデンス\$($pattern_no)_処理時間比較.html"

    info "処理が終了しました。"
    info "作成されたデータと処理時間.htmlファイルを確認してください。"
    info "終了する場合は、Ctrl+Enterを押下してください。"
}