# ==============================
# SET COMFYUI PATH
# ==============================
$ScriptDir = $PSScriptRoot
$ComfyPath = Join-Path $ScriptDir "ComfyUI"
$AllReq    = Join-Path $ComfyPath "all.txt"
$FinalReq  = Join-Path $ComfyPath "final.txt"
$LogFile   = Join-Path $ComfyPath "install.log"
$LorasPath = Join-Path $ComfyPath "models\loras"
$CustomNodesPath = Join-Path $ComfyPath "custom_nodes"

# ==============================
# START TUNNEL BACKGROUND
# ==============================
Write-Host "Starting Cloudflare Tunnel in background..." -ForegroundColor Yellow

$NginxExe = Join-Path $ScriptDir "nginx\nginx.exe"
if (Test-Path $NginxExe) {
    Start-Process -FilePath $NginxExe `
                  -WorkingDirectory (Join-Path $ScriptDir "nginx") `
                  -WindowStyle Hidden `
                  -RedirectStandardOutput "$ScriptDir\nginx.log" `
                  -RedirectStandardError "$ScriptDir\nginx_err.log"
} else {
    Write-Warning "nginx executable not found at $NginxExe. Falling back to system nginx in PATH."
    Start-Process -FilePath "nginx" `
                  -WindowStyle Hidden `
                  -RedirectStandardOutput "$ScriptDir\nginx.log" `
                  -RedirectStandardError "$ScriptDir\nginx_err.log"
}

# Chạy ngầm cloudflared, ẩn cửa sổ, xuất log ra file cf.log và cf_err.log
Start-Process -FilePath "cloudflared" `
              -ArgumentList "tunnel --url http://localhost:9999" `
              -WindowStyle Hidden `
              -RedirectStandardOutput "$ScriptDir\cf.log" `
              -RedirectStandardError "$ScriptDir\cf_err.log"

Write-Host "[+] Start completed!" -ForegroundColor Green

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Read-Host "Press Enter to continue..."