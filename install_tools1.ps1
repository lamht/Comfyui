<#
.SYNOPSIS
    Automated script to install Python 3.10, Hugging Face CLI, Cloudflare Tunnel CLI, and Git on Windows.
.DESCRIPTION
    This script uses Winget and Pip to install the required tools.
    Requires Administrator privileges (Run as Administrator).
#>

# 1. Check for Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Please run PowerShell as Administrator to execute this script!"
    Exit
}

Write-Host "=== STARTING AUTOMATED INSTALLATION PROCESS (4 TOOLS) ===" -ForegroundColor Cyan

# 2. Install Python 3.10 using Winget
# Create a clean temporary directory for installers if it doesn't exist
$DownloadDir = "$env:TEMP\ScriptDownloads"
if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null }

# Global speed optimization for Pip
$env:PIP_DISABLE_PIP_VERSION_CHECK = "1"
$env:PIP_DEFAULT_TIMEOUT = "60"

# ------------------------------------------------------------------------------
# [1/4] Install Python 3.10
# ------------------------------------------------------------------------------
Write-Host "`n[1/4] Downloading Python 3.10 via curl..." -ForegroundColor Yellow
$PythonInstaller = "$DownloadDir\python_installer.exe"

# Using curl.exe with Location redirection flag for speed
curl.exe -L -o $PythonInstaller "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"

if (Test-Path $PythonInstaller) {
    Write-Host "Installing Python 3.10 silently..." -ForegroundColor Gray
    # Run the installer silently and wait for it to finish
    Start-Process -FilePath $PythonInstaller -ArgumentList "/passive PrependPath=1 Include_test=0" -Wait
    Write-Host "-> Python 3.10 installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to download Python 3.10 installer."
}

# ------------------------------------------------------------------------------
# Refresh PATH environment variable in the current session
# ------------------------------------------------------------------------------
Write-Host "`nUpdating session environment variables..." -ForegroundColor Gray
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ------------------------------------------------------------------------------
# [2/4] Install Hugging Face CLI using Pip
# ------------------------------------------------------------------------------
Write-Host "`n[2/4] Installing Hugging Face CLI..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    # --quiet reduces console rendering overhead, which speeds up processing
    python -m pip install --upgrade pip --quiet
    pip install "huggingface_hub[cli]" --quiet
    Write-Host "-> Hugging Face CLI installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Could not find 'pip' command. Please restart PowerShell and manually run: pip install huggingface_hub[cli]"
}

# ------------------------------------------------------------------------------
# [3/4] Install Cloudflare Tunnel CLI (cloudflared)
# ------------------------------------------------------------------------------
Write-Host "`n[3/4] Downloading Cloudflare Tunnel CLI via curl..." -ForegroundColor Yellow
$CloudflaredInstaller = "$DownloadDir\cloudflared_installer.msi"

curl.exe -L -o $CloudflaredInstaller "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.msi"

if (Test-Path $CloudflaredInstaller) {
    Write-Host "Installing Cloudflare Tunnel..." -ForegroundColor Gray
    # MSI silent install switch is /qn
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$CloudflaredInstaller`" /qn" -Wait
    Write-Host "-> Cloudflare Tunnel CLI installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to download Cloudflare Tunnel installer."
}

# ------------------------------------------------------------------------------
# [4/4] Install Git
# ------------------------------------------------------------------------------
Write-Host "`n[4/4] Downloading Git via curl..." -ForegroundColor Yellow
$GitInstaller = "$DownloadDir\git_installer.exe"

# Direct link to the standalone 64-bit installer setup
curl.exe -L -o $GitInstaller "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe"

if (Test-Path $GitInstaller) {
    Write-Host "Installing Git silently..." -ForegroundColor Gray
    # /VERYSILENT and /NORESTART ensures zero prompts
    Start-Process -FilePath $GitInstaller -ArgumentList "/VERYSILENT /NORESTART" -Wait
    Write-Host "-> Git installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to download Git installer."
}

$ScriptDir = $PSScriptRoot
$ComfyPath = Join-Path $ScriptDir "\Comfyui\ComfyUI"
$CustomNodesPath = Join-Path $ComfyPath "custom_nodes"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$nginxVersion = "nginx-1.26.1"
curl.exe -L -o "nginx.zip" "https://nginx.org/download/$nginxVersion.zip"

Expand-Archive -Path "nginx.zip" -DestinationPath "$ScriptDir\nginx" -Force
Move-Item -Path "$ScriptDir\nginx\$nginxVersion\*" -Destination "$ScriptDir\nginx" -Force
Copy-Item -Path "$ScriptDir\nginx-win.conf" -Destination "$ScriptDir\nginx\nginx.conf" -Force
Remove-Item "nginx.zip"