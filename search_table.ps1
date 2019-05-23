$ErrorActionPreference = "Stop"

. .\lib\display.ps1
. .\lib\ver2db2.ps1

$Host.ui.RawUI.WindowTitle = "テーブル名確認用"

info "テーブル検索処理を開始します。"

while ($true) {
    $found_tables = read_table_remarks

    $found_tables | format-table -AutoSize -Property type, name, remarks

    info "検索処理が終了しました。"
    info "終了する場合は、Ctrl+Enterを押下してください。"
}