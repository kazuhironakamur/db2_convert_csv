$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\コンペアツール\コンペアチェック表作成ツールＤＬ_縦比較版_改修10.xlsm"

$Host.ui.RawUI.WindowTitle = "WORKテーブル出力用"

while ($true) {
    ##########################################################################
    info "テーブル検索処理を開始します。"
    ##########################################################################
    while ($true) {
        $found_tables = read_table_remarks

        if ($found_tables -eq "") { break }

        $found_tables | format-table -AutoSize -Property type, name, remarks

        info "検索処理が終了しました。"
        info "終了する場合は、テーブル名を入力せずに[Enter]キーを押下してください。"
    }

    ##########################################################################
    info "WORKテーブル出力処理を開始します。"
    ##########################################################################
    $table_name = read_table_name
    $table_display_name = get_table_display_name $table_name
    Write-Host "指定されたテーブルのテーブル名は 【 $table_display_name 】 です。"

    $function_id = read_function_id
    $function_name = get_function_name $function_id
    Write-Host "指定された機能IDの機能名は 【 $function_name 】 です。"

    $pattern_no = read_pattern_no
    Write-Host "パターン番号は 【 $pattern_no 】 を使用します。"

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
    
        $read_env = $env -replace "genkou", "現行" -replace "cloud", "クラウド"
        write-host "読み取ったファイル作成指示番号: 環境: $read_env ファイル作成指示番号: $($fmmljp00.flssno)"

        $time.add($env, $fmmljp00)

        # 処理時間整形
        if ($time.$env.strtime -eq "") { $start_time = $time.$env.bcksju  -replace "\.", ":" }
        else                           { $start_time = $time.$env.strtime -replace "\.", ":" }
        $end_time =                                    $time.$env.endtime -replace "\.", ":"

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
    $output_file_path = New-Object System.Collections.Hashtable

    foreach ($env in @('genkou', 'cloud')) {
        $query = @"
SELECT * FROM $table_name WHERE flssno = '$($settings.$env.flssno)'
ORDER BY $($order_keys -join ",")
"@

        $dump = execute_query $query $env $file_headers

        # 最終的なCSVファイルを作成する
        $function_dir = "$($function_id)_$($function_name)"
        if ($(test-path -PathType Container $function_dir) -eq $False) { new-item -ItemType Directory $function_dir | out-null }

        $directory_name = "$function_dir\$env" -replace "genkou", "現行" -replace "cloud", "クラウド"
        if ($(test-path -PathType Container $directory_name) -eq $False) { new-item -ItemType Directory $directory_name | out-null }

        $output_file = "$($directory_name)\$($pattern_no)_$($table_name).csv"

        $output_file_path.add($env, $output_file)

        $dump | Export-Csv $output_file -Encoding Default -NoTypeInformation
    }

    ##########################################################################
    info "コンペアツールを実行します。"
    ##########################################################################
    $e = New-Object PSExcel

    $compare_tool_full_path = Convert-Path $compare_tool_path

    $template_full_path = "$(Split-Path -Parent $compare_tool_full_path)\00_ダウンロード_コンペアチェック表_テンプレート_縦比較.xlsx"
    
    $input_genkou_file_full_path = Convert-Path ".\$($output_file_path.genkou)"
    $input_cloud_file_full_path  = Convert-Path ".\$($output_file_path.cloud)"

    $output_result_full_path = "$(Split-Path -Parent $input_genkou_file_full_path | Split-Path -Parent)\コンペア"

    if ($(test-path -PathType Container $output_result_full_path) -eq $False) { new-item -ItemType Directory $output_result_full_path | out-null }

    try {
        if ($e.Open($compare_tool_full_path)) {
            $e.SetValue(3,  2, $template_full_path)                         | Out-Null
            $e.SetValue(5,  2, $input_genkou_file_full_path)                | Out-Null
            $e.SetValue(7,  2, $input_cloud_file_full_path)                 | Out-Null
            $e.SetValue(9,  2, $output_result_full_path)                    | Out-Null
            $e.SetValue(10, 2, "$($pattern_no)_比較結果_$($table_name)")    | Out-Null
            $e.SetValue(11, 2, "0")                                         | Out-Null

            if ($e.PressButton('コンペア実行')) {
                info "コンペアが終了しました。"
            }
            else {
                error "コンペアに失敗しました。"
                
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

    $diff_time = [Math]::Abs($elapsed_time.cloud.TotalSeconds - $elapsed_time.genkou.TotalSeconds)
    $rate_time = [Math]::Abs([Math]::Truncate(($elapsed_time.cloud.TotalSeconds / $elapsed_time.genkou.TotalSeconds - 1) * 100))

    $bgcolor = " bgcolor=""lightskyblue"""
    $time_message = "クラウドのほうが $diff_time 秒 速い"
    $rate_message = "クラウドのほうが $rate_time % 速い"
    if ($elapsed_time.cloud.TotalSeconds -gt $elapsed_time.genkou.TotalSeconds){
        $bgcolor = " bgcolor=""red"""
        $time_message = "クラウドのほうが $diff_time 秒 遅い"
        $rate_message = "クラウドのほうが $rate_time % 遅い"    
    }
    elseif ($elapsed_time.cloud.TotalSeconds -eq $elapsed_time.genkou.TotalSeconds) {
        $bgcolor = ""
        $time_message = "現行とクラウドは秒単位で同程度"
        $rate_message = "現行とクラウドは秒単位で同程度" 
    }

    "<html>
<body>
    <table border=""1"">
        <thead>
            <th>現行処理時間</th>
            <th>クラウド処理時間</th>
            <th>差分(秒)<br />クラウド - 現行</th>
            <th>遅延率<br />クラウド / 現行</th>
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
            <th>環境</th>
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
                <td>現行</td>
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
                <td>クラウド</td>
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
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)_処理時間比較_$($table_name).html"

    info "不要な一時ファイルを削除します。"
    remove-item temporary*

    info "処理が終了しました。"
    info "作成されたデータと処理時間.htmlファイルを確認してください。"
    info "終了する場合は、Ctrl+Enterを押下してください。"
}