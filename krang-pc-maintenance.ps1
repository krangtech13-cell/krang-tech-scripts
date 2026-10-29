<#
  Krang Tech - PC Maintenance Script
  ----------------------------------
  What it does:
    1. Shows how much free space each drive has
    2. Clears temp files (yours + Windows')
    3. Empties the Recycle Bin
    4. Checks your drives' health
    5. Checks Windows Defender status
    6. Checks for pending Windows updates
    7. Shows how long since your last restart
    8. Saves a report to your Desktop

  How to run it:
    - Right-click Start > "Terminal (Admin)" or "Windows PowerShell (Admin)"
    - Go to the folder with this file, e.g.:   cd $HOME\Downloads
    - Preview first (deletes nothing):         powershell -ExecutionPolicy Bypass -File .\krang-pc-maintenance.ps1 -DryRun
    - Run it for real:                          powershell -ExecutionPolicy Bypass -File .\krang-pc-maintenance.ps1

  Works with Windows PowerShell 5.1 (built into Windows 10/11).
#>

param(
    [switch]$DryRun   # Preview mode: shows what WOULD be deleted, deletes nothing
)

$report = New-Object System.Collections.Generic.List[string]
function Say($text, $color = "White") {
    Write-Host $text -ForegroundColor $color
    $report.Add($text)
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

Say "==============================================" Cyan
Say "  Krang Tech PC Maintenance  -  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" Cyan
if ($DryRun) { Say "  DRY RUN: nothing will be deleted" Yellow }
Say "==============================================" Cyan
if (-not $isAdmin) {
    Say "[!] Not running as Administrator. Some steps will be skipped." Yellow
}

# ---------- 1. Disk space ----------
Say "`n[1] Disk space" Green
$drivesBefore = @{}
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
    $totalGB = [math]::Round($_.Size / 1GB, 1)
    $pct     = [math]::Round(($_.FreeSpace / $_.Size) * 100)
    $drivesBefore[$_.DeviceID] = $_.FreeSpace
    $color = "White"
    if ($pct -lt 15) { $color = "Red" }
    Say ("    {0}  {1} GB free of {2} GB ({3}% free)" -f $_.DeviceID, $freeGB, $totalGB, $pct) $color
}

# ---------- 2. Temp files ----------
Say "`n[2] Cleaning temp files" Green
function Clear-Folder($path) {
    if (-not (Test-Path $path)) { return 0 }
    $freed = 0
    Get-ChildItem -Path $path -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
        $size = $_.Length
        if ($DryRun) {
            $freed += $size
        } else {
            try {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                $freed += $size
            } catch { }  # File in use - skip it, that's normal
        }
    }
    if (-not $DryRun) {
        # Remove now-empty folders, deepest first
        Get-ChildItem -Path $path -Recurse -Force -Directory -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }
    return $freed
}

$tempFolders = @($env:TEMP)
if ($isAdmin) { $tempFolders += "$env:SystemRoot\Temp" }

$totalFreed = 0
foreach ($folder in $tempFolders) {
    $freed = Clear-Folder $folder
    $totalFreed += $freed
    Say ("    {0}: {1} MB" -f $folder, [math]::Round($freed / 1MB, 1))
}
$verb = "Freed"
if ($DryRun) { $verb = "Would free" }
Say ("    {0} about {1} MB (files in use are skipped)" -f $verb, [math]::Round($totalFreed / 1MB, 1)) Cyan

# ---------- 3. Recycle Bin ----------
Say "`n[3] Recycle Bin" Green
if ($DryRun) {
    Say "    Skipped in dry run"
} else {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Say "    Emptied"
    } catch {
        Say "    Already empty (or couldn't be emptied)"
    }
}

# ---------- 4. Drive health ----------
Say "`n[4] Drive health" Green
try {
    Get-PhysicalDisk -ErrorAction Stop | ForEach-Object {
        $color = "White"
        if ($_.HealthStatus -ne "Healthy") { $color = "Red" }
        Say ("    {0} ({1}): {2}" -f $_.FriendlyName, $_.MediaType, $_.HealthStatus) $color
    }
} catch {
    Say "    Couldn't read drive health on this PC" Yellow
}

# ---------- 5. Windows Defender ----------
Say "`n[5] Windows Defender" Green
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    $avColor = "Red"
    if ($mp.AntivirusEnabled) { $avColor = "White" }
    Say ("    Antivirus on:        {0}" -f $mp.AntivirusEnabled) $avColor
    Say ("    Real-time protection: {0}" -f $mp.RealTimeProtectionEnabled)
    Say ("    Definitions age:     {0} day(s)" -f $mp.AntivirusSignatureAge)
    if ($mp.QuickScanEndTime) {
        Say ("    Last quick scan:     {0}" -f $mp.QuickScanEndTime)
    } else {
        Say "    Last quick scan:     never" Yellow
    }
} catch {
    Say "    Defender status unavailable (another antivirus may be in use)" Yellow
}

# ---------- 6. Windows Update ----------
Say "`n[6] Pending Windows updates (this can take a minute...)" Green
try {
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result   = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
    if ($result.Updates.Count -eq 0) {
        Say "    Up to date"
    } else {
        Say ("    {0} update(s) waiting:" -f $result.Updates.Count) Yellow
        foreach ($u in $result.Updates) { Say ("      - {0}" -f $u.Title) }
        Say "    Install them in Settings > Windows Update" Yellow
    }
} catch {
    Say "    Couldn't check updates right now" Yellow
}

# ---------- 7. Uptime ----------
Say "`n[7] Time since last restart" Green
$boot   = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $boot
$color  = "White"
if ($uptime.TotalDays -gt 7) { $color = "Yellow" }
Say ("    {0} days, {1} hours" -f $uptime.Days, $uptime.Hours) $color
if ($uptime.TotalDays -gt 7) { Say "    Tip: restart soon so updates can finish installing" Yellow }

# ---------- 8. Save report ----------
$desktop    = [Environment]::GetFolderPath("Desktop")
$reportPath = Join-Path $desktop ("PC-Report-{0}.txt" -f (Get-Date -Format "yyyy-MM-dd_HHmm"))
Say "`n=============================================="  Cyan
Say "  Done! Report saved to: $reportPath" Cyan
Say "==============================================" Cyan
$report | Out-File -FilePath $reportPath -Encoding UTF8
