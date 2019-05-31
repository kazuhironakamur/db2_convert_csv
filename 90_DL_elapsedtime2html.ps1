$ErrorActionPreference = "Stop"

. .\_settings.ps1
. .\lib\display.ps1
. .\lib\ver2app.ps1
. .\lib\ver2db2.ps1
. .\lib\ver2systemtest.ps1

$Host.ui.RawUI.WindowTitle = "DL系 処理時間比較"

$function_id = $null

$function_id = read_function_id $function_id
$function_name = get_function_name $function_id
Write-Host "指定された機能IDの機能名は 【 $function_name 】 です。"

$pattern_no = read_pattern_no
Write-Host "パターン番号は 【 $pattern_no 】 を使用します。"

create_evidence_directories $function_id $function_name $pattern_no

$today = get-date -format "yyyy-MM-dd"
$input_times = New-Object System.Collections.Hashtable

foreach ($env in @('genkou', 'cloud')) {
    while ($true) {
        $msg = $($env -replace 'genkou', '現行' -replace 'cloud', 'クラウド') + "の時刻情報を入力してください "
        $t = Read-Host $msg
        $t = $t.trim()
        $t = $t -replace '\(','' -replace '\)',''

        if ($t -match "^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$") {
            $input_times.add($env, $t)
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

$elapsed_time = New-Object System.Collections.Hashtable

foreach ($env in @("genkou", "cloud")) {
    $t = get-date $input_times.$env
    $elapsed_time.add($env, $t)
}

$html = generate_elaplsed_times_html $function_id $function_name $pattern_no $elapsed_time $null
$html | out-file -Encoding default "$($function_id)_$($function_name)\$($pattern_no)\エビデンス\$($pattern_no)_処理時間比較.html"

info "処理が終了しました。[Enter]キーで終了"
read-host