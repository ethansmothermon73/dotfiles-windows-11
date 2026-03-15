# Install-WSL-Distros.ps1
# Installs WSL with Kali Linux and Ubuntu
# Must be run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n[*] $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

# ── Check Windows version (WSL 2 requires Windows 10 build 19041+) ──────────
$build = [System.Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
    Write-Fail "WSL 2 requires Windows 10 build 19041 or later. Current build: $build"
    exit 1
}

Write-Status "Windows build $build detected — OK"

# ── Enable WSL and Virtual Machine Platform features ────────────────────────
Write-Status "Enabling Windows Subsystem for Linux feature..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

Write-Status "Enabling Virtual Machine Platform feature..."
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

Write-Success "Windows features enabled."

# ── Set WSL default version to 2 ────────────────────────────────────────────
Write-Status "Setting WSL default version to 2..."
wsl --set-default-version 2
Write-Success "WSL default version set to 2."

# ── Install distributions ────────────────────────────────────────────────────
$distros = @(
    @{ Name = "Kali Linux"; Id = "kali-linux" },
    @{ Name = "Ubuntu 20.04"; Id = "Ubuntu-20.04" }
)

foreach ($distro in $distros) {
    Write-Status "Installing $($distro.Name)..."
    try {
        wsl --install -d $distro.Id
        Write-Success "$($distro.Name) installation initiated."
    } catch {
        Write-Fail "Failed to install $($distro.Name): $_"
    }
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "======================================================" -ForegroundColor Yellow
Write-Host "  Installation complete!" -ForegroundColor Yellow
Write-Host "  A REBOOT IS REQUIRED to finish setting up WSL." -ForegroundColor Yellow
Write-Host "  After rebooting, launch each distro from the Start" -ForegroundColor Yellow
Write-Host "  menu to complete the initial setup (create a user)." -ForegroundColor Yellow
Write-Host "======================================================" -ForegroundColor Yellow
Write-Host ""

$reboot = Read-Host "Reboot now? (y/n)"
if ($reboot -eq 'y' -or $reboot -eq 'Y') {
    Write-Status "Rebooting in 10 seconds... Press Ctrl+C to cancel."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}
