<#
.SYNOPSIS
    Script tự động cài đặt Python 3.10, Hugging Face CLI, Cloudflare Tunnel CLI và Git trên Windows.
.DESCRIPTION
    Script này sử dụng Winget và Pip để cài đặt các công cụ. 
    Yêu cầu chạy dưới quyền Administrator (Run as Administrator).
#>

# 1. Kiểm tra quyền Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Vui lòng chạy PowerShell dưới quyền Administrator (Run as Administrator) để thực thi script này!"
    Exit
}

Write-Host "=== BẮT ĐẦU QUÁ TRÌNH CÀI ĐẶT TỰ ĐỘNG (4 CÔNG CỤ) ===" -ForegroundColor Cyan

# 2. Cài đặt Python 3.10 bằng Winget
Write-Host "`n[1/4] Đang cài đặt Python 3.10..." -ForegroundColor Yellow
winget install Python.Python.3.10 --override "/passive PrependPath=1 Include_test=0" --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Cài đặt Python 3.10 thành công!" -ForegroundColor Green
} else {
    Write-Warning "Có thể Python 3.10 đã được cài đặt trước đó hoặc có lỗi xảy ra."
}

# 3. Cập nhật lại biến môi trường PATH ngay trong phiên làm việc này để dùng được lệnh python/pip luôn
Write-Host "Đang cập nhật biến môi trường hệ thống..." -ForegroundColor Gray
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 4. Cài đặt Hugging Face CLI bằng Pip
Write-Host "`n[2/4] Đang cài đặt Hugging Face CLI..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    python -m pip install --upgrade pip
    pip install "huggingface_hub[cli]"
    Write-Host "-> Cài đặt Hugging Face CLI thành công!" -ForegroundColor Green
} else {
    Write-Error "Không tìm thấy lệnh 'pip'. Bạn hãy khởi động lại PowerShell và chạy lại lệnh: pip install huggingface_hub[cli]"
}

# 5. Cài đặt Cloudflare Tunnel CLI bằng Winget
Write-Host "`n[3/4] Đang cài đặt Cloudflare Tunnel CLI (cloudflared)..." -ForegroundColor Yellow
winget install Cloudflare.cloudflared --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Cài đặt Cloudflare Tunnel CLI thành công!" -ForegroundColor Green
} else {
    Write-Warning "Có thể Cloudflare Tunnel đã được cài đặt trước đó hoặc lệnh winget trả về mã bỏ qua."
}

# 6. Cài đặt Git bằng Winget (BƯỚC MỚI THÊM VÀO)
Write-Host "`n[4/4] Đang cài đặt Git..." -ForegroundColor Yellow
winget install Git.Git --exact --accept-source-agreements --accept-package-agreements

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> Cài đặt Git thành công!" -ForegroundColor Green
} else {
    Write-Warning "Có thể Git đã được cài đặt trước đó."
}

Write-Host "`n=== HOÀN THÀNH TẤT CẢ CÀI ĐẶT ===" -ForegroundColor Cyan
Write-Host "LƯU Ý: Vui lòng TẮT hẳn cửa sổ PowerShell này đi và MỞ LẠI cửa sổ mới để tất cả các lệnh (python, huggingface-cli, cloudflared, git) hoạt động chính xác." -ForegroundColor Magenta