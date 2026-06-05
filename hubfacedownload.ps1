$ErrorActionPreference = "Stop"

# ==============================
# SET TOKEN
# ==============================
# $env:HF_TOKEN = "hf_your_token_here"

# ==============================
# INSTALL HF CLI (hf)
# ==============================
Write-Host "Kiểm tra và cài đặt Hugging Face CLI (hf)..." -ForegroundColor Yellow
if (!(Get-Command hf -ErrorAction SilentlyContinue)) {
    # Lệnh cài đặt hf CLI chính thức dành cho Windows PowerShell
    Invoke-RestMethod -Uri "https://hf.co/cli/install.ps1" | Invoke-Expression
}

# Đảm bảo PATH có hf (tương đương với /root/.local/bin trên Linux)
$LocalBin = Join-Path $HOME ".local\bin"
if ($env:Path -notlike "*$LocalBin*") {
    $env:Path += ";$LocalBin"
}

# Tăng tốc download
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"

# ==============================
# LOGIN
# ==============================
if (![string]::IsNullOrEmpty($env:HF_TOKEN)) {
    Write-Host "Đang đăng nhập vào Hugging Face..." -ForegroundColor Cyan
    hf auth login --token $env:HF_TOKEN
} else {
    Write-Host "[WARN] No HF_TOKEN provided, downloading public models only" -ForegroundColor Yellow
}

# ==============================
# BASE PATH
# ==============================
$Base = Join-Path $PSScriptRoot "ComfyUI\models"

# Tạo các thư mục nếu chưa tồn tại (bao gồm cả diffusion_models ở đoạn dưới)
$SubDirs = @("loras", "checkpoints", "clip", "vae", "diffusion_models")
foreach ($Dir in $SubDirs) {
    $TargetDir = Join-Path $Base $Dir
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
}

# ==============================
# DOWNLOAD LORA
# ==============================
Write-Host "`n--- ĐANG TẢI LORAS ---" -ForegroundColor Cyan

# https://huggingface.co/Aitrepreneur/FLX/blob/main/scg-anatomy-female-v2.safetensors
hf download Aitrepreneur/FLX scg-anatomy-female-v2.safetensors --local-dir "$Base\loras"

# https://huggingface.co/uriel353/flux-female-anatomy/resolve/main/flux-female-anatomy.safetensors?download=true
hf download uriel353/flux-female-anatomy flux-female-anatomy.safetensors --local-dir "$Base\loras"
# v4g1n4, n4k3d

# ==============================
# DOWNLOAD LORA (FACE SWAP)
# ==============================
hf download Alissonerdx/BFS-Best-Face-Swap bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors --local-dir "$Base\loras"

hf download ali-vilab/ACE_Plus portrait/comfyui_portrait_lora64.safetensors --local-dir "$Base\loras"
if (Test-Path "$Base\loras\portrait\comfyui_portrait_lora64.safetensors") {
    Move-Item -Path "$Base\loras\portrait\comfyui_portrait_lora64.safetensors" -Destination "$Base\loras\" -Force
}

hf download ali-vilab/ACE_Plus subject/comfyui_subject_lora16.safetensors --local-dir "$Base\loras"
if (Test-Path "$Base\loras\subject\comfyui_subject_lora16.safetensors") {
    Move-Item -Path "$Base\loras\subject\comfyui_subject_lora16.safetensors" -Destination "$Base\loras\" -Force
}

# https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/blob/main/Klein-consistency.safetensors
hf download dx8152/Flux2-Klein-9B-Consistency Klein-consistency.safetensors --local-dir "$Base\loras"

# https://huggingface.co/gmp-dev/gmp-lora/blob/1786940ba90ccc3509970d1cb3541b2fccfd3de7/Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors
hf download gmp-dev/gmp-lora Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors --local-dir "$Base\loras"
if (Test-Path "$Base\loras\Lora\Likeness\realisticVaginasGod_sdVSGp1S.safetensors") {
    Move-Item -Path "$Base\loras\Lora\Likeness\realisticVaginasGod_sdVSGp1S.safetensors" -Destination "$Base\loras\" -Force
}

# hf download fal/FLUX.2-dev-Turbo flux.2-turbo-lora.safetensors --local-dir "$Base\loras"

# ==============================
# DOWNLOAD CHECKPOINT
# ==============================
Write-Host "`n--- ĐANG TẢI CHECKPOINTS ---" -ForegroundColor Cyan

# hf download black-forest-labs/FLUX.2-klein-9b flux-2-klein-9b.safetensors --local-dir "$Base\diffusion_models"

# https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors?download=true
hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir "$Base\diffusion_models"

# https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-kv-fp8/resolve/main/flux-2-klein-9b-kv-fp8.safetensors?download=true
# hf download black-forest-labs/FLUX.2-klein-9b-kv-fp8 flux-2-klein-9b-kv-fp8.safetensors --local-dir "$Base\diffusion_models"

# https://huggingface.co/jackzheng/flux-fill-FP8/blob/main/fluxFillFP8_v10.safetensors
# hf download jackzheng/flux-fill-FP8 fluxFillFP8_v10.safetensors --local-dir "$Base\diffusion_models"
  
# ==============================
# DOWNLOAD CLIP
# ==============================
Write-Host "`n--- ĐANG TẢI CLIP ---" -ForegroundColor Cyan

hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir "$Base\clip"
if (Test-Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors") {
    Move-Item -Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors" -Destination "$Base\clip\" -Force
}

# https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true
# hf download comfyanonymous/flux_text_encoders clip_l.safetensors --local-dir "$Base\clip"

# https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors?download=true
# hf download comfyanonymous/flux_text_encoders t5xxl_fp16.safetensors --local-dir "$Base\clip"
  
# ==============================
# DOWNLOAD VAE
# ==============================
Write-Host "`n--- ĐANG TẢI VAE ---" -ForegroundColor Cyan

hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$Base\vae"
if (Test-Path "$Base\vae\split_files\vae\flux2-vae.safetensors") {
    Move-Item -Path "$Base\vae\split_files\vae\flux2-vae.safetensors" -Destination "$Base\vae\" -Force
}

# https://huggingface.co/lovis93/testllm/resolve/ed9cf1af7465cebca4649157f118e331cf2a084f/ae.safetensors?download=true
# hf download lovis93/testllm ae.safetensors --local-dir "$Base\vae"

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================
Write-Host "`n--- ĐANG TẢI CÁC MODEL BỔ SUNG (DROPBOX) ---" -ForegroundColor Cyan

# https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=0
Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1" -OutFile "$Base\loras\pusfix-klein.safetensors"

# https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=0
Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1" -OutFile "$Base\loras\klein_lora_face1.safetensors"

Write-Host "`n✅ Download complete!" -ForegroundColor Green