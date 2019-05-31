$ErrorActionPreference = "Stop"

. .\lib\display.ps1

$Host.ui.RawUI.WindowTitle = "エビデンスファイル収集"

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

$evidence_dirs = search_latest_evidence_directorires

""
info "以下のディレクトリへエビデンスを収集します。"
"現行エビデンス収集先     : $($evidence_dirs.genkou)"
"クラウドエビデンス収集先 : $($evidence_dirs.cloud)"
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
            move_and_rename_file $f $evidence_dirs.genkou
        }
        elseif ($to -eq 'c') {
            info "クラウドフォルダーへ収集します。"
            move_and_rename_file $f $evidence_dirs.cloud
        }
        elseif ($to -eq 'x') {
            info "ファイルを破棄します。"
            remove-item $f.fullname
        }
    }
}

read-host "[Enter]キーで終了します。"