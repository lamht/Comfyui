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

Write-Host "Using ComfyUI at: $ComfyPath" -ForegroundColor Cyan
Write-Host ""

# ==============================
# ACTIVATE VENV
# ==============================
$VenvActivate = Join-Path $ComfyPath "venv\Scripts\Activate.ps1"
if (Test-Path $VenvActivate) {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    . $VenvActivate
}

Write-Host ""
# ==============================
# INSTALL CORE
# ==============================
Write-Host "Upgrading pip, setuptools, and wheel..." -ForegroundColor Yellow
python -m pip install --upgrade pip setuptools wheel

Write-Host "Installing core requirements..." -ForegroundColor Yellow
$CoreReq = Join-Path $ComfyPath "requirements.txt"
python -m pip install -r "$CoreReq" --prefer-binary
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to install core requirements."
    Read-Host "Press Enter to exit..."
    Exit 1
}

Write-Host ""
# ==============================
# DOWNLOAD NODES (PHẦN MỚI THÊM VÀO)
# ==============================
Write-Host "=== DOWNLOADING CUSTOM NODES ===" -ForegroundColor Cyan

# Tạo thư mục custom_nodes nếu chưa có
if (!(Test-Path $CustomNodesPath)) { 
    New-Item -ItemType Directory -Path $CustomNodesPath -Force | Out-Null 
}

# 1. Tải và giải nén file custom_nodes.zip từ Dropbox
$ZipPath = Join-Path $ComfyPath "custom_nodes.zip"
Write-Host "-> Downloading custom_nodes.zip..." -ForegroundColor Gray
# Đổi dl=0 thành dl=1 để tải trực tiếp file
Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&st=8lx5fxip&dl=1" -OutFile $ZipPath

Write-Host "-> Extracting custom_nodes.zip..." -ForegroundColor Gray
# Giải nén đè (-Force tương đương với -o trong unzip)
Expand-Archive -Path $ZipPath -DestinationPath $ComfyPath -Force
# Xóa file zip sau khi giải nén xong cho sạch máy
Remove-Item $ZipPath -Force

# 2. Git clone các kho lưu trữ (Kiểm tra nếu chưa có thư mục thì mới clone để tránh báo lỗi)
$RgthreePath = Join-Path $CustomNodesPath "rgthree-comfy"
if (!(Test-Path $RgthreePath)) {
    Write-Host "-> Cloning rgthree-comfy..." -ForegroundColor Gray
    git clone https://github.com/rgthree/rgthree-comfy.git $RgthreePath
} else {
    Write-Host "-> rgthree-comfy already exists, skipping clone." -ForegroundColor DarkYellow
}

$ManagerPath = Join-Path $CustomNodesPath "comfyui-manager"
if (!(Test-Path $ManagerPath)) {
    Write-Host "-> Cloning comfyui-manager..." -ForegroundColor Gray
    git clone https://github.com/ltdrdata/ComfyUI-Manager $ManagerPath
} else {
    Write-Host "-> comfyui-manager already exists, skipping clone." -ForegroundColor DarkYellow
}

Write-Host "[+] Custom nodes setup completed!" -ForegroundColor Green

Write-Host ""
# ==============================
# INSTALL CUSTOM NODES DEPENDENCIES
# ==============================
if (Test-Path $AllReq)   { Remove-Item $AllReq -Force }
if (Test-Path $FinalReq) { Remove-Item $FinalReq -Force }

if (Test-Path $CustomNodesPath) {
    Write-Host "Scanning custom nodes requirements..." -ForegroundColor Yellow
    $ReqFiles = Get-ChildItem -Path $CustomNodesPath -Filter "requirements.txt" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($File in $ReqFiles) {
        if (Test-Path $File.FullName) {
            Get-Content $File.FullName | Add-Content $AllReq
            "`n" | Add-Content $AllReq
        }
    }
}

Write-Host "Installing pip-tools..." -ForegroundColor Yellow
python -m pip install pip-tools
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to install pip-tools."
    Read-Host "Press Enter to exit..."
    Exit 1
}

Write-Host "Compiling custom node requirements to '$FinalReq'..." -ForegroundColor Yellow
python -m piptools.pip_compile "$AllReq" -o "$FinalReq" --resolver=backtracking *>$LogFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Compile failed -> fallback to all.txt" -ForegroundColor Yellow
    if (Test-Path $AllReq) {
        Copy-Item $AllReq $FinalReq -Force
    }
} else {
    Write-Host "[+] Compile success" -ForegroundColor Green
}

Write-Host "Installing custom node requirements..." -ForegroundColor Yellow
python -m pip install -r "$FinalReq" --prefer-binary --upgrade-strategy only-if-needed *>> $LogFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: pip install failed. Check '$LogFile' for details."
    Read-Host "Press Enter to exit..."
    Exit 1
}

Write-Host ""
# ==============================
# DOWNLOAD ADDITIONAL MODELS (LoRAs)
# ==============================
Write-Host "=== DOWNLOADING ADDITIONAL MODELS ===" -ForegroundColor Cyan

if (!(Test-Path $LorasPath)) { 
    New-Item -ItemType Directory -Path $LorasPath -Force | Out-Null 
}

$Model1Path = Join-Path $LorasPath "pusfix-klein.safetensors"
if (!(Test-Path $Model1Path)) {
    Write-Host "-> Downloading pusfix-klein.safetensors..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1" -OutFile $Model1Path
}

$Model2Path = Join-Path $LorasPath "klein_lora_face1.safetensors"
if (!(Test-Path $Model2Path)) {
    Write-Host "-> Downloading klein_lora_face1.safetensors..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1" -OutFile $Model2Path
}

Write-Host "[+] Models download completed!" -ForegroundColor Green

Write-Host ""
# ==============================
# FIX TORCH
# ==============================
Write-Host "Checking/Fixing PyTorch (CUDA 13.0)..." -ForegroundColor Yellow
python -m pip uninstall torch torchvision torchaudio -y *>$null
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
if ($LASTEXITCODE -ne 0) {
    Write-Warning "WARNING: Failed to reinstall torch packages from PyTorch index."
}

# ==============================
# START COMFYUI BACKGROUND
# ==============================
Write-Host "Starting ComfyUI in background..." -ForegroundColor Yellow

# Chạy ngầm python, ẩn cửa sổ, xuất log ra file comfy.log và comfy_err.log
Start-Process -FilePath "python" `
              -ArgumentList "main.py --listen 0.0.0.0 --port 8188" `
              -WorkingDirectory $ComfyPath `
              -WindowStyle Hidden `
              -RedirectStandardOutput "$ScriptDir\comfy.log" `
              -RedirectStandardError "$ScriptDir\comfy_err.log"


# ==============================
# START TUNNEL BACKGROUND
# ==============================
Write-Host "Starting Cloudflare Tunnel in background..." -ForegroundColor Yellow

# Chạy ngầm cloudflared, ẩn cửa sổ, xuất log ra file cf.log và cf_err.log
Start-Process -FilePath "cloudflared" `
              -ArgumentList "tunnel --url http://localhost:8188" `
              -WindowStyle Hidden `
              -RedirectStandardOutput "$ScriptDir\cf.log" `
              -RedirectStandardError "$ScriptDir\cf_err.log"

Write-Host "[+] Start completed!" -ForegroundColor Green

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Read-Host "Press Enter to continue..."