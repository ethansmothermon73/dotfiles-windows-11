# Windows Setup Script
# Requires: Administrator privileges
# This script customizes Windows, installs applications, sets wallpaper, and installs WSL

# Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "This script requires administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit
}

Write-Host "Starting Windows Setup Script..." -ForegroundColor Green

# ============================================================================
# 1. SET WINDOWS TO DARK MODE
# ============================================================================
Write-Host "`nSetting Windows to Dark Mode..." -ForegroundColor Cyan

$darkModeRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $darkModeRegPath)) {
    New-Item -Path $darkModeRegPath -Force | Out-Null
}

Set-ItemProperty -Path $darkModeRegPath -Name "AppsUseLightTheme" -Value 0 -Type DWord
Set-ItemProperty -Path $darkModeRegPath -Name "SystemUsesLightTheme" -Value 0 -Type DWord

Write-Host "Dark mode enabled" -ForegroundColor Green

# ============================================================================
# 2. CUSTOMIZE TASKBAR (Hide Date/Time, Clean Look)
# ============================================================================
Write-Host "`nCustomizing Taskbar..." -ForegroundColor Cyan

$taskbarRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Hide the clock/date/time
Set-ItemProperty -Path $taskbarRegPath -Name "ShowSecondsInSystemClock" -Value 0 -Type DWord
Set-ItemProperty -Path $taskbarRegPath -Name "ShowClock" -Value 0 -Type DWord

# Center taskbar icons (Windows 11)
Set-ItemProperty -Path $taskbarRegPath -Name "TaskbarAl" -Value 1 -Type DWord

# Use smaller taskbar icons for cleaner look
Set-ItemProperty -Path $taskbarRegPath -Name "TaskbarSmallIcons" -Value 1 -Type DWord

Write-Host "Taskbar customized" -ForegroundColor Green

# ============================================================================
# 3. DOWNLOAD AND SET WALLPAPER
# ============================================================================
Write-Host "`nSetting wallpaper..." -ForegroundColor Cyan

$wallpaperDir = "$env:USERPROFILE\Pictures\Wallpapers"
if (-not (Test-Path $wallpaperDir)) {
    New-Item -ItemType Directory -Path $wallpaperDir -Force | Out-Null
}

$wallpaperPath = "$wallpaperDir\mr-robot-wallpaper.png"
$wallpaperUrl = "https://raw.githubusercontent.com/ChristianLempa/hackbox/main/src/assets/mr-robot-wallpaper.png"

try {
    Write-Host "Downloading wallpaper..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -ErrorAction Stop
    Write-Host "Wallpaper downloaded successfully" -ForegroundColor Green
    
    # Set wallpaper using registry
    $regPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $regPath -Name "Wallpaper" -Value $wallpaperPath
    
    # Apply wallpaper via WinAPI
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void SetWallpaper(string path) {
            SystemParametersInfo(20, 0, path, 3);
        }
    }
"@
    
    [Wallpaper]::SetWallpaper($wallpaperPath)
    Write-Host "Wallpaper applied" -ForegroundColor Green
}
catch {
    Write-Host "Error downloading wallpaper: $_" -ForegroundColor Yellow
}

# ============================================================================
# 4. INSTALL APPLICATIONS USING WINGET
# ============================================================================
Write-Host "`nInstalling applications..." -ForegroundColor Cyan

# Define all packages to install
$appsToInstall = @(
    @{"id" = "Microsoft.WindowsTerminal"; "name" = "Windows Terminal"},
    @{"id" = "Google.Chrome"; "name" = "Google Chrome"},
    @{"id" = "Microsoft.VisualStudioCode"; "name" = "Visual Studio Code"},
    @{"id" = "1Password.1Password"; "name" = "1Password"},
    @{"id" = "Docker.DockerDesktop"; "name" = "Docker Desktop"},
    @{"id" = "Git.Git"; "name" = "Git"},
    @{"id" = "Helm.Helm"; "name" = "Helm"},
    @{"id" = "Kubernetes.kubectl"; "name" = "kubectl"},
    @{"id" = "ShiningLight.OpenSSL"; "name" = "OpenSSL"},
    @{"id" = "HashiCorp.Terraform"; "name" = "Terraform"},
    @{"id" = "HashiCorp.Vagrant"; "name" = "Vagrant"}
)

# Install each application
foreach ($app in $appsToInstall) {
    Write-Host "Installing $($app.name)..."
    try {
        Start-Process -FilePath "winget" -ArgumentList "install --id $($app.id) --accept-source-agreements --accept-package-agreements -e" -Wait -NoNewWindow
        Write-Host "$($app.name) installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error installing $($app.name): $_" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

# ============================================================================
# 5. CONFIGURE WINDOWS TERMINAL SETTINGS
# ============================================================================
Write-Host "`nConfiguring Windows Terminal..." -ForegroundColor Cyan

$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Wait a moment for Windows Terminal to create settings file if it doesn't exist
Start-Sleep -Seconds 3

try {
    # Read existing settings or create new if doesn't exist
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    }
    else {
        $settings = @{
            "`$schema" = "https://raw.githubusercontent.com/microsoft/terminal/main/doc/cascadia/SettingsSchema.json"
            "profiles" = @{"defaults" = @{}}
            "schemes" = @()
        }
    }

    # Ensure schemes array exists
    if (-not $settings.schemes) {
        $settings | Add-Member -NotePropertyName "schemes" -NotePropertyValue @() -Force
    }

    # Remove existing xcad scheme if it exists
    $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne "xcad" })

    # Add xcad color scheme
    $xcadScheme = @{
        "background" = "#1A1A1A"
        "black" = "#121212"
        "blue" = "#2B4FFF"
        "brightBlack" = "#666666"
        "brightBlue" = "#5C78FF"
        "brightCyan" = "#5AC8FF"
        "brightGreen" = "#905AFF"
        "brightPurple" = "#5EA2FF"
        "brightRed" = "#BA5AFF"
        "brightWhite" = "#FFFFFF"
        "brightYellow" = "#685AFF"
        "cursorColor" = "#FFFFFF"
        "cyan" = "#28B9FF"
        "foreground" = "#F1F1F1"
        "green" = "#7129FF"
        "name" = "xcad"
        "purple" = "#2883FF"
        "red" = "#A52AFF"
        "selectionBackground" = "#FFFFFF"
        "white" = "#F1F1F1"
        "yellow" = "#3D2AFF"
    }

    $settings.schemes += $xcadScheme

    # Ensure profiles.defaults exists
    if (-not $settings.profiles.defaults) {
        $settings.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue @{} -Force
    }

    # Configure profile defaults
    $profileDefaults = @{
        "colorScheme" = "xcad"
        "cursorShape" = "filledBox"
        "font" = @{
            "face" = "Hack Nerd Font"
            "size" = 14
        }
        "historySize" = 12000
        "intenseTextStyle" = "bright"
        "opacity" = 95
        "padding" = "8"
        "scrollbarState" = "visible"
        "useAcrylic" = $false
    }

    # Merge profile defaults
    foreach ($key in $profileDefaults.Keys) {
        $settings.profiles.defaults | Add-Member -NotePropertyName $key -NotePropertyValue $profileDefaults[$key] -Force
    }

    # Define profiles with tab colors
    $profileList = @(
        @{
            "commandline" = "C:\Program Files\PowerShell\7\pwsh.exe --NoLogo"
            "elevate"     = $false
            "guid"        = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
            "hidden"      = $false
            "icon"        = "https://raw.githubusercontent.com/ethansmothermon73/wsl-icons/main/icons8-powershell-20.png"
            "name"        = "PowerShell"
            "source"      = "Windows.Terminal.PowershellCore"
            "tabColor"    = "#02240c"
        },
        @{
            "guid"              = "{07b52e3e-de2c-5db4-bd2d-ba144ed6c273}"
            "hidden"            = $false
            "icon"              = "https://raw.githubusercontent.com/ethansmothermon73/wsl-icons/main/icons8-ubuntu-20.png"
            "name"              = "Ubuntu 20.04.6 LTS"
            "source"            = "Windows.Terminal.Wsl"
            "startingDirectory" = "\\wsl$\Ubuntu-20.04\home\xcad"
            "tabColor"          = "#021024"
        },
        @{
            "guid"              = "{46ca431a-3a87-5fb3-83cd-11ececc031d2}"
            "hidden"            = $false
            "icon"              = "https://raw.githubusercontent.com/ethansmothermon73/wsl-icons/main/icons8-fsociety-mask-20.png"
            "name"              = "kali-linux"
            "source"            = "Windows.Terminal.Wsl"
            "startingDirectory" = "\\wsl.localhost\kali-linux\home\xcad"
            "tabColor"          = "#540357"
        },
        @{
            "guid"     = "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}"
            "icon"     = "https://raw.githubusercontent.com/ethansmothermon73/wsl-icons/main/icons8-cmd-20.png"
            "name"     = "Commandline"
            "tabColor" = "#5028ad"
        },
        @{
            "guid"     = "{b453ae62-4e3d-5e58-b989-0a998ec441b8}"
            "hidden"   = $true
            "icon"     = "https://raw.githubusercontent.com/ethansmothermon73/wsl-icons/main/icons8-azure-20.png"
            "name"     = "Azure Cloud Shell"
            "source"   = "Windows.Terminal.Azure"
            "tabColor" = "#2885ad"
        }
    )

    # Ensure profiles.list exists, then merge tab colors into matching profiles by guid
    if (-not $settings.profiles.list) {
        $settings.profiles | Add-Member -NotePropertyName "list" -NotePropertyValue @() -Force
    }

    foreach ($newProfile in $profileList) {
        $existing = $settings.profiles.list | Where-Object { $_.guid -eq $newProfile.guid }
        if ($existing) {
            # Update tab color on existing profile
            $existing | Add-Member -NotePropertyName "tabColor" -NotePropertyValue $newProfile.tabColor -Force
        } else {
            # Add new profile entry
            $settings.profiles.list += [PSCustomObject]$newProfile
        }
    }

    # Set default color scheme and theme
    if (-not $settings.defaultProfile) {
        $settings | Add-Member -NotePropertyName "defaultProfile" -NotePropertyValue "" -Force
    }

    # Save settings back to file
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "Windows Terminal configured successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error configuring Windows Terminal: $_" -ForegroundColor Yellow
}

# ============================================================================
# 6. INSTALL WSL (Windows Subsystem for Linux)
# ============================================================================
Write-Host "`nInstalling WSL..." -ForegroundColor Cyan

try {
    # Install WSL with default distro (Ubuntu)
    wsl --install --no-launch
    Write-Host "WSL installation initiated" -ForegroundColor Green
    Write-Host "Note: WSL installation requires a system restart to complete." -ForegroundColor Yellow
    
    # Update WSL
    Write-Host "`nUpdating WSL..." -ForegroundColor Cyan
    wsl --update
    Write-Host "WSL updated" -ForegroundColor Green
}
catch {
    Write-Host "Error installing/updating WSL: $_" -ForegroundColor Yellow
}

# ============================================================================
# COMPLETION
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nChanges applied:" -ForegroundColor Cyan
Write-Host "✓ Dark mode enabled" -ForegroundColor Green
Write-Host "✓ Taskbar customized (centered, hidden clock)" -ForegroundColor Green
Write-Host "✓ Wallpaper set (Mr. Robot)" -ForegroundColor Green
Write-Host "✓ Core applications installed:" -ForegroundColor Green
Write-Host "  - Windows Terminal" -ForegroundColor Green
Write-Host "  - Google Chrome" -ForegroundColor Green
Write-Host "  - Visual Studio Code" -ForegroundColor Green
Write-Host "✓ Developer tools installed:" -ForegroundColor Green
Write-Host "  - 1Password" -ForegroundColor Green
Write-Host "  - Docker Desktop" -ForegroundColor Green
Write-Host "  - Git" -ForegroundColor Green
Write-Host "  - Helm" -ForegroundColor Green
Write-Host "  - kubectl" -ForegroundColor Green
Write-Host "  - OpenSSL" -ForegroundColor Green
Write-Host "  - Terraform" -ForegroundColor Green
Write-Host "  - Vagrant" -ForegroundColor Green
Write-Host "✓ Windows Terminal configured:" -ForegroundColor Green
Write-Host "  - Color scheme: xcad" -ForegroundColor Green
Write-Host "  - Font: Hack Nerd Font (14pt)" -ForegroundColor Green
Write-Host "  - Cursor: filledBox" -ForegroundColor Green
Write-Host "  - Opacity: 95%" -ForegroundColor Green
Write-Host "  - Tab colors: PowerShell (#02240c), Ubuntu (#021024), Kali (#540357), CMD (#5028ad), Azure (#2885ad)" -ForegroundColor Green
Write-Host "✓ WSL installed and updated" -ForegroundColor Green

Write-Host "`nNote: Some changes may require a system restart to take full effect." -ForegroundColor Yellow
Write-Host "After installation completes, please restart your computer." -ForegroundColor Yellow

Read-Host "Press Enter to close this window"
