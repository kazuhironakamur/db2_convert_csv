$ErrorActionPreference = "Stop"

. .\settings.ps1

$max_depth = 8

Class PanKuzu {
    $list

    PanKuzu() {
        #write-host "パンくずリストの初期化"
        $this.list = New-Object System.Collections.ArrayList
    }

    push($value) {
        $this.list.add($value)
    }

    pop() {
        $this.list.removeat($this.list.count - 1)
    }

    [string]print() {
        return $this.list -join " > "
    }
}

function get_header() {
    $query = @"
connect to $($settings.odbc_name) user $($settings.conn_user) using $($settings.conn_pass);

export to temporary_columns.csv of del
select colname
from syscat.columns
where tabschema=(select current_schema from dual)
and tabname='$($settings.menu_table_name)'
order by colno
;
"@

    $query | Out-File -Encoding default temporary.sql
    db2cmd /c /w /i db2 -tvf temporary.sql | Out-Null
    if($? -eq $False) {
        Write-Host -ForegroundColor Red "ERROR: DB2へのクエリ発行に失敗しました。"
        Write-Host ""
        Write-Host "接続情報 :"
        Write-Host "ODBC : $($settings.odbc_name)   USER : $($settings.conn_user)   PASSWORD : $($settings.conn_pass)"
        Write-Host ""
        Write-Host "発行クエリ :"
        Write-Host $query
        read-host "エラー内容を確認してください。[Enter]キーで終了"
        exit -1
    }

    # 抽出した列をCSVから読み込んでarraylist化する
    # output.csvのヘッダー行として使用する
    $cols = import-csv temporary_columns.csv -Header "COLNAME" -Encoding Default
    $headers = New-Object System.Collections.ArrayList
    foreach ($c in $cols) { $headers.add($c.COLNAME) | out-null }

    Remove-Item temporary_columns.csv
    Remove-Item temporary.sql

    return $headers
}

if (Test-Path menu_tree.txt)    { Remove-Item menu_tree.txt    }
if (Test-Path menu_pankuzu.txt) { Remove-Item menu_pankuzu.txt }

function search_menu($menu_id, $depth) {
    if ($depth -gt $max_depth) {
        "メニュー階層の深さが $max_depth を超えました。" | Out-File -Append -Encoding default menu_tree.txt
        "メニュー階層の深さが $max_depth を超えました。" | Out-File -Append -Encoding default menu_pankuzu.txt
        return
    }

    $query = @"
connect to $($settings.odbc_name) user $($settings.conn_user) using $($settings.conn_pass);

export to temporary_menu.csv of del
select * from UBCVMBB0 where stmnid = '$menu_id'
;
"@
    
    $query | Out-File -Encoding default temporary.sql
    db2cmd /c /w /i db2 -tvf temporary.sql | Out-Null
    if($? -eq $False) {
        Write-Host -ForegroundColor Red "ERROR: DB2へのクエリ発行に失敗しました。"
        Write-Host ""
        Write-Host "接続情報 :"
        Write-Host "ODBC : $($settings.odbc_name)   USER : $($settings.conn_user)   PASSWORD : $($settings.conn_pass)"
        Write-Host ""
        Write-Host "発行クエリ :"
        Write-Host $query
        read-host "エラー内容を確認してください。[Enter]キーで終了"
        exit -1
    }
    
    $menus = import-csv temporary_menu.csv -Header $h -Encoding Default

    foreach ($menu in $menus) {
        if ($menu.SLMNBG -eq "") { continue }
        if ($menu.SLPGNM -eq "") { continue }

        "$("  " * $depth + "- ")$($menu.SLMNBG)_$($menu.SLMNTX)" | Out-File -Append -Encoding default menu_tree.txt

        if ($menu.SLPGKB -eq 'M') {
            $depth++
            $pankuzu.push("$($menu.SLMNBG)")
            search_menu $menu.SLPGNM $depth
            $depth--
            $pankuzu.pop()
        }
        else {
            "$($pankuzu.print()) > $($menu.SLMNBG)_$($menu.SLMNTX)" | Out-File -Append -Encoding default menu_pankuzu.txt
        }
    }
}

$h = get_header
$pankuzu = New-Object PanKuzu
search_menu $settings.root_menu_id 0

Remove-Item temporary*