$ErrorActionPreference = "Stop"

. .\lib\display.ps1
. .\lib\ver2db2.ps1

$Host.ui.RawUI.WindowTitle = "�e�[�u�����m�F�p"

info "�e�[�u�������������J�n���܂��B"

while ($true) {
    $found_tables = read_table_remarks

    $found_tables | format-table -AutoSize -Property type, name, remarks

    info "�����������I�����܂����B"
    info "�I������ꍇ�́ACtrl+Enter���������Ă��������B"
}