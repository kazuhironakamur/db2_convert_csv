$ErrorActionPreference = "Stop"

. .\lib\display.ps1
. .\lib\ver2menus.ps1

$Host.ui.RawUI.WindowTitle = "メニュー検索用"

info "メニュー検索処理を開始します。"
info "メニューパンくずリストを読み込んでいます..."
$menus = get-content .\lib\menu_pankuzu.txt
info "メニューパンくずリストを読み込みました。"

while ($true) {
    $menu_name = read_menu_name

    $menu_name = $menu_name -replace " ", ".*"
    $found_menu = $menus | Select-String -Pattern ".*$($menu_name).*" | Select-Object -First 10
    $found_menu

    if ($found_menu.count -eq 0) {
        error "メニューが見つかりませんでした。"
    }
    elseif ($found_menu.count -eq 10) {
        warn "件数が多すぎる可能性があります。10件を上限として表示しています。"
    }

    info "検索処理が終了しました。"
    info "終了する場合は、Ctrl+Enterを押下してください。"
}