function read_menu_name() {
    while($True) {
        $menu_name = read-host "対象のメニュー名を入力してください "
        
        if ($menu_name -eq "") {
            Write-Host -ForegroundColor Red "メニュー名は必須です。"
            continue
        }

        break
    }
    
    return $menu_name
}