
$ScriptDir = $PSScriptRoot
$ComfyPath = Join-Path $ScriptDir "\Comfyui\ComfyUI"
$CustomNodesPath = Join-Path $ComfyPath "custom_nodes"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
git clone https://github.com/lamht/Comfyui.git

$nginxVersion = "nginx-1.26.1"
curl.exe -L -o "nginx.zip" "https://nginx.org/download/$nginxVersion.zip"

Expand-Archive -Path "nginx.zip" -DestinationPath "$ScriptDir\nginx" -Force
Move-Item -Path "$ScriptDir\nginx\$nginxVersion\*" -Destination "$ScriptDir\nginx" -Force
Copy-Item -Path "$ScriptDir\Comfyui\nginx-win.conf" -Destination "$ScriptDir\nginx\nginx.conf" -Force
Remove-Item "nginx.zip"
Start-Process .\nginx.exe -WorkingDirectory "$ScriptDir\nginx" -WindowStyle Hidden

curl.exe -L -o "ComfyUI.7z" "https://github.com/Comfy-Org/ComfyUI/releases/download/v0.24.0/ComfyUI_windows_portable_nvidia_cu126.7z"

# This creates the folder if missing, but does nothing (and throws no error) if it already exists
New-Item -ItemType Directory -Path "$ScriptDir\Comfyui" -Force

# 1. Clean up old installation
Remove-Item -Path "$ScriptDir\Comfyui\ComfyUI" -Recurse -Force

# 2. OPTIMIZED: Extracts contents directly, bypassing the "ComfyUI_windows_portable" folder name
Write-Host "Extracting ComfyUI..." -ForegroundColor Cyan
tar -xvf "ComfyUI.7z" --strip-components=1 -C "$ScriptDir\Comfyui"

# 3. Clean up the zip archive
Remove-Item "ComfyUI.7z" -Force

Write-Host "=== DOWNLOADING CUSTOM NODES ===" -ForegroundColor Cyan

# Tạo thư mục custom_nodes nếu chưa có
if (!(Test-Path $CustomNodesPath)) { 
    New-Item -ItemType Directory -Path $CustomNodesPath -Force | Out-Null 
}

# 1. Tải và giải nén file custom_nodes.zip từ Dropbox
$ZipPath = Join-Path $ComfyPath "custom_nodes.zip"
Write-Host "-> Downloading custom_nodes.zip..." -ForegroundColor Gray
# Keep dl=1 to force direct download
$DropboxUrl = 'https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&st=8lx5fxip&dl=1'
curl.exe -L -o "$ZipPath" $DropboxUrl

Write-Host "-> Extracting custom_nodes.zip..." -ForegroundColor Gray
# Giải nén đè (-Force tương đương với -o trong unzip)
Expand-Archive -Path $ZipPath -DestinationPath $ComfyPath -Force
# Xóa file zip sau khi giải nén xong cho sạch máy
Remove-Item $ZipPath -Force

# 2. Git clone các kho lưu trữ (Kiểm tra nếu chưa có thư mục thì mới clone để tránh báo lỗi)
Remove-Item -Path "$CustomNodesPath\rgthree-comfy" -Recurse -Force
Remove-Item -Path "$CustomNodesPath\ComfyUI-Crystools" -Recurse -Force
Remove-Item -Path "$CustomNodesPath\comfyui-manager" -Recurse -Force

$RgthreePath = Join-Path $CustomNodesPath "rgthree-comfy"
if (!(Test-Path $RgthreePath)) {
    Write-Host "-> Cloning rgthree-comfy..." -ForegroundColor Gray
    git clone https://github.com/rgthree/rgthree-comfy.git $RgthreePath
} else {
    Write-Host "-> rgthree-comfy already exists, skipping clone." -ForegroundColor DarkYellow
}

$CrystoolsPath = Join-Path $CustomNodesPath "ComfyUI-Crystools"
if (!(Test-Path $CrystoolsPath)) {
    Write-Host "-> Cloning ComfyUI-Crystools..." -ForegroundColor Gray
    git clone https://github.com/crystian/ComfyUI-Crystools.git $CrystoolsPath
} else {
    Write-Host "-> ComfyUI-Crystools already exists, skipping clone." -ForegroundColor DarkYellow
}

$ManagerPath = Join-Path $CustomNodesPath "comfyui-manager"
if (!(Test-Path $ManagerPath)) {
    Write-Host "-> Cloning comfyui-manager..." -ForegroundColor Gray
    git clone https://github.com/ltdrdata/ComfyUI-Manager $ManagerPath
} else {
    Write-Host "-> comfyui-manager already exists, skipping clone." -ForegroundColor DarkYellow
}

Write-Host "[+] Custom nodes setup completed!" -ForegroundColor Green

