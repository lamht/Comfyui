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
Write-Host "`n[1/4] Installing Python 3.10..." -ForegroundColor Yellow
winget install Python.Python.3.10 --override "/passive PrependPath=1 Include_test=0" --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Python 3.10 installed successfully!" -ForegroundColor Green
} else {
    Write-Warning "Python 3.10 might already be installed or an error occurred."
}

# 3. Refresh PATH environment variable in the current session
Write-Host "Updating session environment variables..." -ForegroundColor Gray
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 4. Install Hugging Face CLI using Pip
Write-Host "`n[2/4] Installing Hugging Face CLI..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    python -m pip install --upgrade pip
    pip install "huggingface_hub[cli]"
    Write-Host "-> Hugging Face CLI installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Could not find 'pip' command. Please restart PowerShell and manually run: pip install huggingface_hub[cli]"
}

# 5. Install Cloudflare Tunnel CLI using Winget
Write-Host "`n[3/4] Installing Cloudflare Tunnel CLI (cloudflared)..." -ForegroundColor Yellow
winget install Cloudflare.cloudflared --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Cloudflare Tunnel CLI installed successfully!" -ForegroundColor Green
} else {
    Write-Warning "Cloudflare Tunnel might already be installed or winget returned a skip code."
}

# 6. Install Git using Winget
Write-Host "`n[4/4] Installing Git..." -ForegroundColor Yellow
winget install Git.Git --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Git installed successfully!" -ForegroundColor Green
} else {
    Write-Warning "Git might already be installed."
}

Write-Host "`n=== ALL INSTALLATIONS COMPLETED ===" -ForegroundColor Cyan
Write-Host "NOTE: Please CLOSE this PowerShell window and OPEN a new one for all commands (python, huggingface-cli, cloudflared, git) to work correctly." -ForegroundColor Magenta