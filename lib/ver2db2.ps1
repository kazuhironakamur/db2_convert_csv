# 呼び出し元シェルからの相対パスになるので注意
. .\lib\ver2tables.ps1

function execute_query($query, $env, $headers) {
    $timestamp = get-date -format "yyyyMMdd_HHmmss_ffffff"
    
    $query = @"
connect to $($settings.$env.odbc_name) user $($settings.$env.conn_user) using $($settings.$env.conn_pass);
export to $($timestamp)_temporary_dump.csv of del
$query
for read only;
"@
    $query | Out-File -Encoding default "$($timestamp)_temporary.sql"
    db2cmd /c /w /i db2 -tvf "$($timestamp)_temporary.sql" | Out-File -Encoding default "$($timestamp)_temporary_stdout.txt"

    if($? -eq $False) {
        error "ERROR: DB2へのクエリ発行に失敗しました。"
        error ""
        error "エラー内容 :"
        error $(Get-Content temporary_stdout.txt)
        error ""
        error "接続情報 :"
        error "環境: $env"
        error "ODBC : $($settings.$env.odbc_name)   USER : $($settings.$env.conn_user)   PASSWORD : $($settings.$env.conn_pass)"
        error ""
        error "発行クエリ :"
        error $query
        read-host "エラー内容を確認してください。[Enter]キーで終了"
        exit -1
    }

    $dump = import-csv "$($timestamp)_temporary_dump.csv" -Header $headers -Encoding default
    if($dump.count -eq 0) {
        error "ERROR: データ件数が0件です。"
        error ""
        error "接続情報 :"
        error "環境: $env"
        error "ODBC : $($settings.$env.odbc_name)   USER : $($settings.$env.conn_user)   PASSWORD : $($settings.$env.conn_pass)"
        error ""
        error "発行クエリ :"
        error $query
        read-host "エラー内容を確認してください。[Enter]キーで終了"
        exit -1
    }

    remove-item "$($timestamp)_temporary*"

    return $dump
}

function get_table_display_name($t_name) {
    $r = $tables.$t_name
    
    $esc_chars = @(" ", "　", "\\")
    foreach ($c in $esc_chars) { $r = $r -replace $c, "" }

    if ($r -match "[(|（][B|Ｂ][)|）]") {
        Write-Host -ForegroundColor Yellow "ボディテーブル(B)です。ヘッダーテーブル(H)も比較が必要です。"
    }
    if ($r -match "[(|（][H|Ｈ][)|）]") {
        Write-Host -ForegroundColor Yellow "ヘッダーテーブル(H)です。ボディテーブル(B)も比較が必要です。"
    }

    return $r   
}

function table_is_exist($t_name) {
    if ($tables.$t_name -eq $null) {
        return $False
    }
    
    return $True
}

function read_table_name() {
    while($True) {
        $table_name = read-host "対象のテーブル名を入力してください "
        $table_name = $table_name.trim().ToUpper()

        if ($table_name -eq "") {
            Write-Host -ForegroundColor Red "テーブル名は必須です。"
            continue
        }

        if ($(table_is_exist $table_name) -eq $False) {
            Write-Host -ForegroundColor Red "指定されたテーブルは定義されていません。"
            continue
        }

        break
    }
    
    return $table_name
}

function search_table_remarks($search_string) {
    $r = New-Object System.Collections.Hashtable
    # 通常テーブルを格納する(トランザクション、マスタ系)
    $normal = New-Object System.Collections.Hashtable
    # WORKテーブルを格納する(先頭がW)
    $work = New-Object System.Collections.Hashtable

    $found_tables = New-Object PSCustomObject

    $search_string = $search_string -replace " ", "*"

    $found_tables = foreach ($key in $tables.Keys) {
        if ($key -match "^VIEW_") { continue }
        if ($key -match "^TMP_") { continue }
        if ($key -match "^KR_") { continue }
        if ($key -match "E$") { continue }
        if ($key -match "S$") { continue }
        if ($key -match "W$") { continue }

        if ($tables.$key -like "*$search_string*") {
            $type = "通常テーブル"
            if ($key -match "^W") { $type = "WORKテーブル" }

            [PSCustomObject] @{
                type = $type
                name = $key
                remarks = $tables.$key
                remarks_length = $($tables.$key).length
            }
        }
    }
    
    if ($found_tables.count -eq 0) {
        return $false
    }

    $found_tables = $found_tables | sort -Descending type, remarks_length, remarks, name

    return $found_tables
}

function read_table_remarks() {
    while ($True) {
        $table_name = read-host "検索するテーブル名を入力してください "
        
        # テーブル名が入力されなかった場合、後続の処理を続行するように変更
        #if ($table_name -eq "") {
        #    Write-Host -ForegroundColor Red "テーブル名は必須です。"
        #    continue
        #}

        if ($table_name -eq "") {
            return ""
        }

        $found_tables = search_table_remarks $table_name
        if ($found_tables -eq $False) {
            Write-Host -ForegroundColor Red "指定された検索条件でテーブルが見つかりませんでした。検索条件を見直してください。"
            continue
        }

        break
    }
    
    return $found_tables
}