$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\excel.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$compare_tool_path = ".\コンペアツール\コンペアチェック表作成ツールＤＬ_縦比較版_改修10.xlsm"

$Host.ui.RawUI.WindowTitle = "処理時間比較 URLに起動IDが含まれていない場合に使用"

$function_id = $null

$function_id = read_function_id $function_id
$function_name = get_function_name $function_id
Write-Host "指定された機能IDの機能名は 【 $function_name 】 です。"

$pattern_no = read_pattern_no
Write-Host "パターン番号は 【 $pattern_no 】 を使用します。"

create_evidence_directories $function_id $function_name $pattern_no

$today = get-date -format "yyyy-MM-dd"
$timestamps = New-Object System.Collections.Hashtable

foreach ($env in @('genkou', 'cloud')) {
    while ($true) {
        $msg = $($env -replace 'genkou', '現行' -replace 'cloud', 'クラウド') + "の時刻情報を入力してください "
        $t = $t.trim()
        $t = Read-Host $msg

        if ($t -match "^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$") {
            $timestamps.add($env, $t)
            break
        }
        else {
            error "入力された時刻が正しくありません。"
        }
    }
}

##########################################################################
info "処理時間を比較します"
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
<head>
    <style type=""text/css"">
        body { font-family:""ＭＳ ゴシック"", sans-serif; }
    </style>
</head>
<body>
    <table border=""1"">
        <thead>
            <th>機能ID</th>
            <th>機能名</th>
            <th>テストパターンNo.</th>
            <th>現行処理時間</th>
            <th>クラウド処理時間</th>
            <th>処理時間差分(秒)<br />クラウド - 現行</th>
            <th>差分(秒)コメント<br />クラウド - 現行</th>
            <th>遅延率コメント<br />クラウド / 現行</th>
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
</html>" | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\エビデンス\$($pattern_no)_処理時間比較.html"

info "不要な一時ファイルを削除します。"
remove-item temporary*

info "処理が終了しました。"
info "処理時間.htmlファイルを確認してください。[Enter]キーで終了"
read-host
