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
            Write-Error "�w�肳�ꂽ�t�@�C����������܂���B($path)"
            return $False
        }
        
        $full_path = Convert-Path $path
        Write-Verbose "��΃p�X�ɕϊ����܂����B($full_path)"

        try {
            $this.b = $this.e.Workbooks.Open($full_path)
        }
        catch {
            Write-Error "�t�@�C�����J���܂���B($path)"
            return $False
        }
        Write-Verbose "WorkBook( $($this.b.name) )���J���܂����B"

        $this.s = $this.b.Worksheets.Item(1)
        Write-Verbose "WorkSheet( $($this.s.name) )���J���܂����B"

        return $True
    }

    [string]GetValue($row_index, $col_index) {
        if ($this.__IsInteger($row_index) -eq $False) {
            Write-Error "��1�����̍s�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }
        
        if ($this.__IsInteger($col_index) -eq $False) {
            Write-Error "��2�����̗�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }

        $value = $this.s.Cells.Item($row_index, $col_index).Text
        Write-Verbose "Cell($($row_index), $($col_index))����l���擾���܂����B(Text = $value)"

        return $value
    }

    [boolean]SetValue($row_index, $col_index, $value) {
        if ($this.__IsInteger($row_index) -eq $False) {
            Write-Error "��1�����̍s�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }
        
        if ($this.__IsInteger($col_index) -eq $False) {
            Write-Error "��2�����̗�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }

        try  {
            $this.s.Cells.Item($row_index, $col_index).Value = $value
        }
        catch {
            Write-Error "Cell($($row_index), $($col_index))�֒l��ݒ�ł��܂���ł����B(Value = $value)"
        }

        Write-Verbose "Cell($($row_index), $($col_index))�֒l��ݒ肵�܂����B(Value = $value)"

        return $True
    }

    [Object]FetchRow($index) {
        if ($this.__IsInteger($index) -eq $False) {
            Write-Error "�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }
        Write-Verbose "�s($($index))���擾���܂����B"

        try {
            return $this.s.Rows($index).Value2
        }
        catch {
            Write-Error "�s($($index))�̎擾�Ɏ��s���܂����B"
            return $False
        }
        
    }

    [Object]FetchColumn($index) {
        if ($this.__IsInteger($index) -eq $False) {
            Write-Error "�C���f�b�N�X�͐��l����͂��Ă��������B"
            return $False
        }
        Write-Verbose "��($($index))���擾���܂����B"

        try {
            return $this.s.Columns($index).Value2
        }
        catch {
            Write-Error "��($($index))�̎擾�Ɏ��s���܂����B"
            return $False
        }
    }

    [boolean]PressButton($name) {
        Write-Verbose "�{�^���̈ꗗ���擾���܂����B"
        foreach($btn in $this.s.Buttons()) {
            if ($btn.Caption -eq $name) {
                Write-Verbose "�{�^��(Caption = $name)�������܂����B�o�^����Ă���}�N�������s���܂��B"
                $this.e.Run($btn.OnAction)
                return $?
            }
        }

        Write-Error "�{�^��(Caption = $name)��������܂���ł����B"
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
            Write-Error "�t�@�C���𐳏�ɕ��邱�Ƃ��ł��܂���ł����B"
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