function read_menu_name() {
    while($True) {
        $menu_name = read-host "�Ώۂ̃��j���[������͂��Ă������� "
        
        if ($menu_name -eq "") {
            Write-Host -ForegroundColor Red "���j���[���͕K�{�ł��B"
            continue
        }

        break
    }
    
    return $menu_name
}