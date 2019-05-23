$ErrorActionPreference = "Stop"

. .\lib\display.ps1
. .\lib\ver2menus.ps1

$Host.ui.RawUI.WindowTitle = "���j���[�����p"

info "���j���[�����������J�n���܂��B"
info "���j���[�p���������X�g��ǂݍ���ł��܂�..."
$menus = get-content .\lib\menu_pankuzu.txt
info "���j���[�p���������X�g��ǂݍ��݂܂����B"

while ($true) {
    $menu_name = read_menu_name

    $menu_name = $menu_name -replace " ", ".*"
    $found_menu = $menus | Select-String -Pattern ".*$($menu_name).*" | Select-Object -First 10
    $found_menu

    if ($found_menu.count -eq 0) {
        error "���j���[��������܂���ł����B"
    }
    elseif ($found_menu.count -eq 10) {
        warn "��������������\��������܂��B10��������Ƃ��ĕ\�����Ă��܂��B"
    }

    info "�����������I�����܂����B"
    info "�I������ꍇ�́ACtrl+Enter���������Ă��������B"
}