Class PSExcel {
    $e # excel.exe
    $b # book
    $s # sheet

    PSExcel() {
        $this.e = New-Object -ComObject Excel.Application
        #$this.e.Visible = $true

        $this.b = $null
        $this.s = $null
    }

    [boolean]Open($path) {
        if ($(Test-path $path) -eq $False) {
            Write-Error "指定されたファイルが見つかりません。($path)"
            return $False
        }
        
        $full_path = Convert-Path $path
        Write-Verbose "絶対パスに変換しました。($full_path)"

        try {
            $this.b = $this.e.Workbooks.Open($full_path)
        }
        catch {
            Write-Error "ファイルを開けません。($path)"
            return $False
        }
        Write-Verbose "WorkBook( $($this.b.name) )を開きました。"

        $this.s = $this.b.Worksheets.Item(1)
        Write-Verbose "WorkSheet( $($this.s.name) )を開きました。"

        return $True
    }

    [string]GetValue($row_index, $col_index) {
        if ($this.__IsInteger($row_index) -eq $False) {
            Write-Error "第1引数の行インデックスは数値を入力してください。"
            return $False
        }
        
        if ($this.__IsInteger($col_index) -eq $False) {
            Write-Error "第2引数の列インデックスは数値を入力してください。"
            return $False
        }

        $value = $this.s.Cells.Item($row_index, $col_index).Text
        Write-Verbose "Cell($($row_index), $($col_index))から値を取得しました。(Text = $value)"

        return $value
    }

    [boolean]SetValue($row_index, $col_index, $value) {
        if ($this.__IsInteger($row_index) -eq $False) {
            Write-Error "第1引数の行インデックスは数値を入力してください。"
            return $False
        }
        
        if ($this.__IsInteger($col_index) -eq $False) {
            Write-Error "第2引数の列インデックスは数値を入力してください。"
            return $False
        }

        try  {
            $this.s.Cells.Item($row_index, $col_index).Value = $value
        }
        catch {
            Write-Error "Cell($($row_index), $($col_index))へ値を設定できませんでした。(Value = $value)"
        }

        Write-Verbose "Cell($($row_index), $($col_index))へ値を設定しました。(Value = $value)"

        return $True
    }

    [Object]FetchRow($index) {
        if ($this.__IsInteger($index) -eq $False) {
            Write-Error "インデックスは数値を入力してください。"
            return $False
        }
        Write-Verbose "行($($index))を取得しました。"

        try {
            return $this.s.Rows($index).Value2
        }
        catch {
            Write-Error "行($($index))の取得に失敗しました。"
            return $False
        }
        
    }

    [Object]FetchColumn($index) {
        if ($this.__IsInteger($index) -eq $False) {
            Write-Error "インデックスは数値を入力してください。"
            return $False
        }
        Write-Verbose "列($($index))を取得しました。"

        try {
            return $this.s.Columns($index).Value2
        }
        catch {
            Write-Error "列($($index))の取得に失敗しました。"
            return $False
        }
    }

    [boolean]PressButton($name) {
        Write-Verbose "ボタンの一覧を取得しました。"
        foreach($btn in $this.s.Buttons()) {
            if ($btn.Caption -eq $name) {
                Write-Verbose "ボタン(Caption = $name)を見つけました。登録されているマクロを実行します。"
                $this.e.Run($btn.OnAction)
                return $?
            }
        }

        Write-Error "ボタン(Caption = $name)が見つかりませんでした。"
        return $False
    }

    Save($name) {
        if ($name -eq $null) {
            $this.b.Save()
        }
        else {
            $this.b.SaveAs($name)
        }
    }

    Quit() {
        try {
            $this.b.Close($False)
        }
        catch {
            Write-Error "ファイルを正常に閉じることができませんでした。"
        }
        finally {
            $this.e.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($this.s)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($this.b)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($this.e)
            [GC]::Collect()
        }
    }

    [boolean]__IsInteger($arg) {
        $pattern = "^[0-9]*$"
        return $arg -match $pattern
    }
}