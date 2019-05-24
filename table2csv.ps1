$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\コンペアツール\コンペアチェック表作成ツールＤＬ_縦比較版_改修10.xlsm"

$Host.ui.RawUI.WindowTitle = "テーブル出力用"

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
    info "テーブル出力処理を開始します。"
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
    info "対象テーブルの直近タイムスタンプ取得します。"
    ##########################################################################
    # 当初、insertとupdateで抽出するデータを変更しようかと考えましたが、
    # updateのタイムスタンプはトランザクション内で統一されないことがわかりました。
    # 例)
    # 1伝票の登録で、明細行のタイムスタンプはバラバラになってしまいます。
    # なので、すべてinsert時のタイムスタンプで抽出するように変更しました。
    # 更新データは、登録データの一部なので対象行として全体を俯瞰できます。

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

    Write-Host "■ 現行システム タイムスタンプ"
    Write-Host "ユーザーID  : $($timestamps.genkou.user_id)"
    Write-Host "セッションID: $($timestamps.genkou.session_id)"
    Write-Host "登録日付    : $($timestamps.genkou.insert_date)"
    Write-Host "登録時刻    : $($timestamps.genkou.insert_time)"
    Write-Host ""
    Write-Host "■クラウドシステム タイムスタンプ"
    Write-Host "ユーザーID  : $($timestamps.cloud.user_id)"
    Write-Host "セッションID: $($timestamps.cloud.session_id)"
    Write-Host "登録日付    : $($timestamps.cloud.insert_date)"
    Write-Host "登録時刻    : $($timestamps.cloud.insert_time)"

    ##########################################################################
    info "対象テーブルから主キーを抽出します。"
    ##########################################################################
    # 現行/クラウドでテーブル定義に差異はない前提なので現行からのみ取得する
    $env = 'genkou'
    $query = @"
select colname from syscat.keycoluse where tabname = '$table_name'
order by colseq
"@

    # 抽出した主キーをarraylist化し、order by句で使用する
    $p_keys = execute_query $query $env @("COLNAME")
    $order_keys = New-Object System.Collections.ArrayList
    foreach ($p in $p_keys) { $order_keys.add($p.COLNAME) | out-null }


    ##########################################################################
    info "対象テーブルから列を抽出します。"
    ##########################################################################
    # 現行/クラウドでテーブル定義に差異はない前提なので現行からのみ取得する
    $env = 'genkou'
    $query = @"
select colname
from syscat.columns
where tabschema=(select current_schema from dual)
and tabname='$table_name'
order by colno
"@

    # 抽出した列をarraylist化し、ヘッダー行として使用する
    $cols = execute_query $query $env @("COLNAME")
    $file_headers = New-Object System.Collections.ArrayList
    foreach ($c in $cols) { $file_headers.add($c.COLNAME) | out-null }


    ##########################################################################
    info "対象テーブルをCSV化します。"
    ##########################################################################
    $output_file_path = New-Object System.Collections.Hashtable

    foreach($env in @('genkou', 'cloud')) {
        $query = @"
select * from $table_name where ausr__ = '$($timestamps.$env.user_id)' and awid__ = '$($timestamps.$env.session_id)' 
and addy__ = '$($timestamps.$env.insert_date)' and addb__ = '$($timestamps.$env.insert_time)'
"@

        if ($order_keys.length -gt 0) { $query += "`norder by $($order_keys -join ",")" }

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
    info "WASログから処理時間情報を計測します。"
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
        Write-Host -ForegroundColor Red "ERROR: WASログ情報(FCTLSP00)のACTNMが、現行/クラウドで異なっています。"
        Write-Host -ForegroundColor Red "ERROR: 異なるログの比較は、このツールではサポートされていません。"
        Write-Host -ForegroundColor Red "ERROR: テストを再実行してください。"
        Write-Host "現行システムのACTNM    : $($was_log.genkou.actnm)"
        Write-Host "クラウドシステムのACTNM: $($was_log.cloud.actnm)"
        read-host "エラー内容を確認してください。[Enter]キーで終了"
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
                <td>現行</td>
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
                <td>クラウド</td>
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
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)_処理時間比較.html"

    info "不要な一時ファイルを削除します。"
    remove-item temporary*

    info "処理が終了しました。"
    info "作成されたデータと処理時間.htmlファイルを確認してください。"
    info "終了する場合は、Ctrl+Enterを押下してください。"
}