# Ensure Admin Privileges
Write-Host "=============================================" -ForegroundColor Red
Write-Host "TYPE ANY THING AND DO ENTER TO OPEN Warning: USE AT YOUR OWN RISK!" -ForegroundColor Yellow
Write-Host "This script modifies system settings. Review all changes before running!" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Red
Read-Host "Press Enter to continue"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
    exit
}

# Function to show the menu
function Show-Menu {
    Clear-Host
    Write-Host "Windows Debloat Menu" -ForegroundColor Green
    Write-Host "1. Disable Windows Telemetry"
    Write-Host "2. Disable Windows Recall"
    Write-Host "3. Disable BitLocker"
    Write-Host "4. Uninstall Non-System Pre-installed Apps (Excluding Xbox)"
    Write-Host "5. Create a System Restore Point"
    Write-Host "6. Exit"
}

# Function to create System Restore Point
function Create-RestorePoint {
    Write-Host "Creating System Restore Point..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive"
        Checkpoint-Computer -Description "Restore Point created by Debloater" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "System Restore Point Created Successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create a Restore Point: $_" -ForegroundColor Red
    }
}

# Function to disable telemetry
function Disable-Telemetry {
    Write-Host "Disabling Windows Telemetry..." -ForegroundColor Cyan
    Stop-Service DiagTrack -Force
    Set-Service DiagTrack -StartupType Disabled
    Stop-Service dmwappushservice -Force
    Set-Service dmwappushservice -StartupType Disabled
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null

    # Disable telemetry-related scheduled tasks
    schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE
    schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE

    Write-Host "Telemetry Disabled!" -ForegroundColor Green
}

# Function to disable Windows Recall
function Disable-Recall {
    Write-Host "Disabling Windows Recall..." -ForegroundColor Cyan
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Recall" -Name "EnableRecall" -ErrorAction SilentlyContinue
    Write-Host "Windows Recall Disabled!" -ForegroundColor Green
}

# Function to disable BitLocker
function Disable-BitLocker {
    Write-Host "Checking BitLocker status..." -ForegroundColor Cyan
    $bitlockerStatus = (Get-BitLockerVolume -MountPoint "C:").ProtectionStatus
    if ($bitlockerStatus -eq "On") {
        Write-Host "Disabling BitLocker..." -ForegroundColor Cyan
        Disable-BitLocker -MountPoint "C:"
        Write-Host "BitLocker is now disabled!" -ForegroundColor Green
    } else {
        Write-Host "BitLocker is already disabled!" -ForegroundColor Yellow
    }
}

# Function to uninstall non-system pre-installed apps
function Uninstall-Bloatware {
    Write-Host "Removing unnecessary pre-installed apps..." -ForegroundColor Cyan
    $bloatwareApps = Get-AppxPackage | Where-Object { $_.Name -notmatch "Microsoft.WindowsStore|Microsoft.WindowsCalculator|Microsoft.WindowsDefender|Microsoft.WindowsTerminal|Microsoft.WindowsNotepad|Microsoft.WindowsCamera|Microsoft.WindowsExplorer|Microsoft.WindowsControlPanel" }

    foreach ($app in $bloatwareApps) {
        Write-Host "Removing $($app.Name)..."
        Remove-AppxPackage -Package $app.PackageFullName
    }
    Write-Host "All non-essential apps removed!" -ForegroundColor Green
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        "1" { Disable-Telemetry }
        "2" { Disable-Recall }
        "3" { Disable-BitLocker }
        "4" { Uninstall-Bloatware }
        "5" { Create-RestorePoint }
        "6" { Write-Host "Exiting..."; break }
        default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
    }
    Pause
} while ($choice -ne "6")
