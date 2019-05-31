$__pattern_no_max_length = 6

function pattern_no_is_valid($p_no) {
    return $p_no -match "\d{1,$($__pattern_no_max_length)}"
}

function read_pattern_no() {
    while($True) {
        $pattern_no = read-host "テストパターン番号があれば入力してください。 (1～$('9' * $__pattern_no_max_length)) "
        
        if ($pattern_no -eq "") {
            $pattern_no = '0' * ($__pattern_no_max_length - 1) + '1'
            info "パターン番号の入力を省略しました。パターン番号$($pattern_no)を使用します。"
            break
        }
        
        $pattern_no = '0' * ($__pattern_no_max_length - 1) + $($pattern_no.trim())
        $pattern_no = $pattern_no.Substring($pattern_no.Length - $__pattern_no_max_length, $__pattern_no_max_length)

        
        if ($(pattern_no_is_valid $pattern_no) -eq $False) {
            error "パターン番号の形式が正しくありません。"
            continue
        }

        if ([int]$pattern_no -le 0) {
            error "パターン番号は1以上の正の整数を指定してください。"
            continue
        }

        break
    }
    
    return "P$pattern_no"
}

function create_directory($directory_name) {
    if ($directory_name -eq "") {
        error "ディレクトリの作成に失敗しました。"
        error "ディレクトリ名が設定されていません。(Directory_name = $directory_name)"
    }

    if ($(test-path -PathType Container $directory_name) -eq $False) {
        new-item -ItemType Directory $directory_name | out-null
    }
}

function create_evidence_directories($function_id, $function_name, $pattern_no, $compare_times, $detail) {
    foreach ($env in @('genkou', 'cloud')) {
        $evidence_dir = "$($function_id)_$($function_name)\$($pattern_no)\"
        $work_dir = "$($evidence_dir)\WORK\$env" -replace "genkou", "現行" -replace "cloud", "クラウド"
        create_directory $work_dir
        create_directory $("$evidence_dir\エビデンス\$env" -replace "genkou", "01_現行" -replace "cloud", "02_クラウド")
    }

    create_directory $("$evidence_dir\エビデンス\03_コンペア")
}

function search_latest_evidence_directorires {
    $function_dir_pattern = "^[A-Z]_[A-Z]{2}_[0-9]{4}_*"
    $function_dir = Get-ChildItem -Directory | Select-String -pattern $function_dir_pattern | Sort-Object -Descending LastWriteTime | Select-Object -First 1

    if ($function_dir -eq $null) {
        error "エビデンス格納先ディレクトリが見つかりません。(機能ID_機能名)"
        read-host "[Enter]キーで終了します。"
        exit -1
    }

    $pattern_dir  = Get-ChildItem -Directory $function_dir | Sort-Object -Descending LastWriteTime | Select-Object -First 1
    if ($pattern_dir -eq $null) {
        error "エビデンス格納先ディレクトリが見つかりません。(機能ID_機能名\パターン番号\)"
        read-host "[Enter]キーで終了します。"
        exit -1
    }

    $genkou_dir = "$function_dir\$pattern_dir\エビデンス\01_現行"
    if (!(test-path $genkou_dir)) {
        error "エビデンス格納先ディレクトリが見つかりません。(現行 = $genkou_dir)"
        read-host "[Enter]キーで終了します。"
        exit -1
    }

    $cloud_dir = "$function_dir\$pattern_dir\エビデンス\02_クラウド"
    if (!(test-path $cloud_dir)) {
        error "エビデンス格納先ディレクトリが見つかりません。(クラウド = $cloud_dir)"
        read-host "[Enter]キーで終了します。"
        exit -1
    }

    $dirs = New-Object System.Collections.Hashtable

    $dirs.add('genkou', $genkou_dir)
    $dirs.add('cloud',  $cloud_dir)

    return $dirs
}

function generate_elaplsed_times_html($function_id, $function_name, $pattern_no, $elapsed_time, $detail) {
    $header = @"
<html>
<head>
    <style type=""text/css"">
        body { font-family:""ＭＳ ゴシック"", sans-serif; }
    </style>
</head>
<body>
"@
    
    $footer = @"
</body>
</html>
"@

    if ($elapsed_time.genkou.TotalSeconds -ne $null) {
        $diff_time = $elapsed_time.cloud.TotalSeconds - $elapsed_time.genkou.TotalSeconds
        $rate_time = [Math]::Abs([Math]::Truncate(($elapsed_time.cloud.TotalSeconds / $elapsed_time.genkou.TotalSeconds - 1) * 100))
    }
    else {
        $genkou_total_seconds = $elapsed_time.genkou.Hour * 3600 + $elapsed_time.genkou.Minute * 60 + $elapsed_time.genkou.Second
        $cloud_total_seconds  = $elapsed_time.cloud.Hour * 3600  + $elapsed_time.cloud.Minute * 60  + $elapsed_time.cloud.Second

        $diff_time = $cloud_total_seconds - $genkou_total_seconds
        $rate_time = [Math]::Abs([Math]::Truncate(($cloud_total_seconds / $genkou_total_seconds - 1) * 100))
    }
    
    $bgcolor = " bgcolor=""lightskyblue"""
    $time_message = "クラウドのほうが $([Math]::Abs($diff_time)) 秒 速い"
    $rate_message = "クラウドのほうが $rate_time % 速い"

    if ($diff_time -gt 0){
        $bgcolor = " bgcolor=""red"""
        $time_message = "クラウドのほうが $([Math]::Abs($diff_time)) 秒 遅い"
        $rate_message = "クラウドのほうが $rate_time % 遅い"    
    }
    elseif ($diff_time -eq 0) {
        $bgcolor = ""
        $time_message = "現行とクラウドは秒単位で同程度"
        $rate_message = "現行とクラウドは秒単位で同程度" 
    }

    $compare_table = @"
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
            <td align=""right"" $bgcolor>$([Math]::Abs($diff_time))</td>
            <td$($bgcolor)>$($time_message)</td>
            <td$($bgcolor)>$($rate_message)</td>
        </tr>
    </tbody>
</table>
"@

    if ($detail_table -ne $null) {
        $detail_table = @"
<table border=""1"">
    <thead>
        <th>環境</th>
        $(foreach($prop in $($detail.genkou | Get-Member -MemberType NoteProperty)){
            "<th>$($prop.Name)</th>`n"
        })
    </thead>
    <tbody>
        <tr>
            <td>現行</td>
            $(foreach($prop in $($detail.genkou | Get-Member -MemberType NoteProperty)){
                "<td>$($detail.genkou.$($prop.Name))</td>`n"
            })
        </tr>
        <tr>
            <td>クラウド</td>
            $(foreach($prop in $($detail.cloud | Get-Member -MemberType NoteProperty)){
                "<td>$($detail.cloud.$($prop.Name))</td>`n"
            })
        </tr>
    </tbody>
</table>
"@
    }

    $html = $header
    $html += $compare_table

    if ($detail_table -ne $null) {
        $html += "<br />"
        $html += $detail_table
    }
    $html += $footer

    return $html
}