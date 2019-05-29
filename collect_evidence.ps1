$ErrorActionPreference = "Stop"

. .\lib\display.ps1

$Host.ui.RawUI.WindowTitle = "ファイル収集用"

$IMAGE_EXTENSIONS = @("*.jpg", "*.png")
$OTHER_EXTENSIONS = @("*.pdf", "*.csv", "*.xlsx")

$EXTENSIONS = New-Object System.Collections.ArrayList

foreach ($array in @($IMAGE_EXTENSIONS, $OTHER_EXTENSIONS)) {
    $array | ForEach-Object { $EXTENSIONS.add($_) | Out-Null }
}


info "エビデンスファイル($($EXTENSIONS -join ", "))を収集します。"

$target_dirs = @(
    "$env:USERPROFILE\Pictures\Screenshots",
    "$env:USERPROFILE\downloads"
)

$function_dir_pattern = "[A-Z]_[A-Z]{2}_[0-9]{4}_*"
$function_dir = Get-ChildItem -Directory | Select-String -pattern $function_dir_pattern | Sort-Object -Descending LastWriteTime | Select-Object -First 1
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

""
info "以下のディレクトリへエビデンスを収集します。"
"現行エビデンス収集先     : $genkou_dir"
"クラウドエビデンス収集先 : $cloud_dir"
""
read-host "収集先ディレクトリに間違いがなければ、[Enter]キーで処理を継続してください。間違っている場合はCtrl+Cなどでプログラムを終了してください。 "

function move_and_rename_file($file, $dir) {
    # 画像ファイルは、WinMergeで比較するためにシンプルな名前にリネームする。
    # 同じ順番で現行/クラウドでエビデンスを採取すれば画像名が同一となり、
    # WinMergeで容易に比較することができる。
    if ($file.name -match "\.jpg$|\.png$") {
        # -Recurseをつけないと、-inlucdeが正しく機能しない。謎。
        $exists_files = Get-ChildItem -File -Recurse $dir -include $IMAGE_EXTENSIONS
        
        $file_no = $exists_files.count + 1

        warn "画像ファイルはリネームします。"

        "$dir\$($exists_files.Count + 1)$($f.Extension)"
        Move-Item -Path $file.fullname -Destination "$dir\$($file_no)$($f.Extension)"
    }
    else {
        Move-Item -Path $file.fullname -Destination $dir
    }
}

$default = 'g'
foreach ($d in $target_dirs) {
    foreach ($f in $(Get-ChildItem -File -Recurse $d -Include $EXTENSIONS)) {
        ""
        info "ファイルの仕分け先を選択してください。"
        $f.fullname
        ""

        if ($to -eq 'g') {
            $default = 'c'
        }
        elseif ($to -eq 'c') {
            $default = 'g'
        }

        while ($true) {
            $to = read-host "収集先を選択  g:現行  c:クラウド  x:削除 (default [$default])"

            if ($to -cmatch "^g|c|x$") { break }
            if ($to -eq "") { $to = $default; break }
        }

        if ($to -eq 'g') {
            info "現行フォルダーへ収集します。"
            move_and_rename_file $f $genkou_dir
        }
        elseif ($to -eq 'c') {
            info "クラウドフォルダーへ収集します。"
            move_and_rename_file $f $cloud_dir
        }
        elseif ($to -eq 'x') {
            info "ファイルを破棄します。"
            remove-item $f.fullname
        }
    }
}

read-host "[Enter]キーで終了します。"