$ErrorActionPreference = "Stop"

. .\lib\display.ps1

$Host.ui.RawUI.WindowTitle = "�t�@�C�����W�p"

$IMAGE_EXTENSIONS = @("*.jpg", "*.png")
$OTHER_EXTENSIONS = @("*.pdf", "*.csv", "*.xlsx")

$EXTENSIONS = New-Object System.Collections.ArrayList

foreach ($array in @($IMAGE_EXTENSIONS, $OTHER_EXTENSIONS)) {
    $array | ForEach-Object { $EXTENSIONS.add($_) | Out-Null }
}


info "�G�r�f���X�t�@�C��($($EXTENSIONS -join ", "))�����W���܂��B"

$target_dirs = @(
    "$env:USERPROFILE\Pictures\Screenshots",
    "$env:USERPROFILE\downloads"
)

$function_dir_pattern = "[A-Z]_[A-Z]{2}_[0-9]{4}_*"
$function_dir = Get-ChildItem -Directory | Select-String -pattern $function_dir_pattern | Sort-Object -Descending LastWriteTime | Select-Object -First 1
$pattern_dir  = Get-ChildItem -Directory $function_dir | Sort-Object -Descending LastWriteTime | Select-Object -First 1
if ($pattern_dir -eq $null) {
    error "�G�r�f���X�i�[��f�B���N�g����������܂���B(�@�\ID_�@�\��\�p�^�[���ԍ�\)"
    read-host "[Enter]�L�[�ŏI�����܂��B"
    exit -1
}

$genkou_dir = "$function_dir\$pattern_dir\�G�r�f���X\01_���s"
if (!(test-path $genkou_dir)) {
    error "�G�r�f���X�i�[��f�B���N�g����������܂���B(���s = $genkou_dir)"
    read-host "[Enter]�L�[�ŏI�����܂��B"
    exit -1
}

$cloud_dir = "$function_dir\$pattern_dir\�G�r�f���X\02_�N���E�h"
if (!(test-path $cloud_dir)) {
    error "�G�r�f���X�i�[��f�B���N�g����������܂���B(�N���E�h = $cloud_dir)"
    read-host "[Enter]�L�[�ŏI�����܂��B"
    exit -1
}

""
info "�ȉ��̃f�B���N�g���փG�r�f���X�����W���܂��B"
"���s�G�r�f���X���W��     : $genkou_dir"
"�N���E�h�G�r�f���X���W�� : $cloud_dir"
""
read-host "���W��f�B���N�g���ɊԈႢ���Ȃ���΁A[Enter]�L�[�ŏ������p�����Ă��������B�Ԉ���Ă���ꍇ��Ctrl+C�ȂǂŃv���O�������I�����Ă��������B "

function move_and_rename_file($file, $dir) {
    # �摜�t�@�C���́AWinMerge�Ŕ�r���邽�߂ɃV���v���Ȗ��O�Ƀ��l�[������B
    # �������ԂŌ��s/�N���E�h�ŃG�r�f���X���̎悷��Ή摜��������ƂȂ�A
    # WinMerge�ŗe�Ղɔ�r���邱�Ƃ��ł���B
    if ($file.name -match "\.jpg$|\.png$") {
        # -Recurse�����Ȃ��ƁA-inlucde���������@�\���Ȃ��B��B
        $exists_files = Get-ChildItem -File -Recurse $dir -include $IMAGE_EXTENSIONS
        
        $file_no = $exists_files.count + 1

        warn "�摜�t�@�C���̓��l�[�����܂��B"

        "$dir\$($exists_files.Count + 1)$($f.Extension)"
        Move-Item -Path $file.fullname -Destination "$dir\$($file_no)$($f.Extension)"
    }
    else {
        Move-Item -Path $file.fullname -Destination $dir
    }
}

$default = 'g'
foreach ($d in $target_dirs) {
    foreach ($f in $(Get-ChildItem -File -Recurse $d -Include $EXTENSIONS)) {
        ""
        info "�t�@�C���̎d�������I�����Ă��������B"
        $f.fullname
        ""

        if ($to -eq 'g') {
            $default = 'c'
        }
        elseif ($to -eq 'c') {
            $default = 'g'
        }

        while ($true) {
            $to = read-host "���W���I��  g:���s  c:�N���E�h  x:�폜 (default [$default])"

            if ($to -cmatch "^g|c|x$") { break }
            if ($to -eq "") { $to = $default; break }
        }

        if ($to -eq 'g') {
            info "���s�t�H���_�[�֎��W���܂��B"
            move_and_rename_file $f $genkou_dir
        }
        elseif ($to -eq 'c') {
            info "�N���E�h�t�H���_�[�֎��W���܂��B"
            move_and_rename_file $f $cloud_dir
        }
        elseif ($to -eq 'x') {
            info "�t�@�C����j�����܂��B"
            remove-item $f.fullname
        }
    }
}

read-host "[Enter]�L�[�ŏI�����܂��B"