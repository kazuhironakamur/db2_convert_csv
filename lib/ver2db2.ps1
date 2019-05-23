# �Ăяo�����V�F������̑��΃p�X�ɂȂ�̂Œ���
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
        error "ERROR: DB2�ւ̃N�G�����s�Ɏ��s���܂����B"
        error ""
        error "�G���[���e :"
        error $(Get-Content temporary_stdout.txt)
        error ""
        error "�ڑ���� :"
        error "��: $env"
        error "ODBC : $($settings.$env.odbc_name)   USER : $($settings.$env.conn_user)   PASSWORD : $($settings.$env.conn_pass)"
        error ""
        error "���s�N�G�� :"
        error $query
        read-host "�G���[���e���m�F���Ă��������B[Enter]�L�[�ŏI��"
        exit -1
    }

    $dump = import-csv "$($timestamp)_temporary_dump.csv" -Header $headers -Encoding default
    if($dump.count -eq 0) {
        error "ERROR: �f�[�^������0���ł��B"
        error ""
        error "�ڑ���� :"
        error "��: $env"
        error "ODBC : $($settings.$env.odbc_name)   USER : $($settings.$env.conn_user)   PASSWORD : $($settings.$env.conn_pass)"
        error ""
        error "���s�N�G�� :"
        error $query
        read-host "�G���[���e���m�F���Ă��������B[Enter]�L�[�ŏI��"
        exit -1
    }

    remove-item "$($timestamp)_temporary*"

    return $dump
}

function get_table_display_name($t_name) {
    $r = $tables.$t_name
    
    $esc_chars = @(" ", "�@", "\\")
    foreach ($c in $esc_chars) { $r = $r -replace $c, "" }

    if ($r -match "[(|�i][B|�a][)|�j]") {
        Write-Host -ForegroundColor Yellow "�{�f�B�e�[�u��(B)�ł��B�w�b�_�[�e�[�u��(H)����r���K�v�ł��B"
    }
    if ($r -match "[(|�i][H|�g][)|�j]") {
        Write-Host -ForegroundColor Yellow "�w�b�_�[�e�[�u��(H)�ł��B�{�f�B�e�[�u��(B)����r���K�v�ł��B"
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
        $table_name = read-host "�Ώۂ̃e�[�u��������͂��Ă������� "
        $table_name = $table_name.trim().ToUpper()

        if ($table_name -eq "") {
            Write-Host -ForegroundColor Red "�e�[�u�����͕K�{�ł��B"
            continue
        }

        if ($(table_is_exist $table_name) -eq $False) {
            Write-Host -ForegroundColor Red "�w�肳�ꂽ�e�[�u���͒�`����Ă��܂���B"
            continue
        }

        break
    }
    
    return $table_name
}

function search_table_remarks($search_string) {
    $r = New-Object System.Collections.Hashtable
    # �ʏ�e�[�u�����i�[����(�g�����U�N�V�����A�}�X�^�n)
    $normal = New-Object System.Collections.Hashtable
    # WORK�e�[�u�����i�[����(�擪��W)
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
            $type = "�ʏ�e�[�u��"
            if ($key -match "^W") { $type = "WORK�e�[�u��" }

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
        $table_name = read-host "��������e�[�u��������͂��Ă������� "
        
        # �e�[�u���������͂���Ȃ������ꍇ�A�㑱�̏����𑱍s����悤�ɕύX
        #if ($table_name -eq "") {
        #    Write-Host -ForegroundColor Red "�e�[�u�����͕K�{�ł��B"
        #    continue
        #}

        if ($table_name -eq "") {
            return ""
        }

        $found_tables = search_table_remarks $table_name
        if ($found_tables -eq $False) {
            Write-Host -ForegroundColor Red "�w�肳�ꂽ���������Ńe�[�u����������܂���ł����B�����������������Ă��������B"
            continue
        }

        break
    }
    
    return $found_tables
}