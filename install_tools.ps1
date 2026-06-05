$ErrorActionPreference = "Stop"

# ==============================
# SET TOKEN
# ==============================
# $env:HF_TOKEN = "hf_your_token_here"

# ==============================
# INSTALL HF CLI (hf)
# ==============================
Write-Host "Kiem tra va cai dat Hugging Face CLI (hf)..." -ForegroundColor Yellow
if (!(Get-Command hf -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod -Uri "https://hf.co/cli/install.ps1" | Invoke-Expression
}

# Dam bao PATH co hf
$LocalBin = Join-Path $HOME ".local\bin"
if ($env:Path -notlike "*$LocalBin*") {
    $env:Path += ";$LocalBin"
}

# Tang toc download
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"

# ==============================
# LOGIN
# ==============================
if (![string]::IsNullOrEmpty($env:HF_TOKEN)) {
    Write-Host "Dang dang nhap vao Hugging Face..." -ForegroundColor Cyan
    hf auth login --token $env:HF_TOKEN
} else {
    Write-Host "[WARN] No HF_TOKEN provided, downloading public models only" -ForegroundColor Yellow
}

# ==============================
# BASE PATH
# ==============================
$Base = Join-Path $PSScriptRoot "ComfyUI\models"

# Tao cac thu muc neu chua ton tai
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
Write-Host "`n--- DANG TAI LORAS ---" -ForegroundColor Cyan

hf download Aitrepreneur/FLX scg-anatomy-female-v2.safetensors --local-dir "$Base\loras"
hf download uriel353/flux-female-anatomy flux-female-anatomy.safetensors --local-dir "$Base\loras"

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

hf download dx8152/Flux2-Klein-9B-Consistency Klein-consistency.safetensors --local-dir "$Base\loras"

hf download gmp-dev/gmp-lora Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors --local-dir "$Base\loras"
if (Test-Path "$Base\loras\Lora\Likeness\realisticVaginasGod_sdVSGp1S.safetensors") {
    Move-Item -Path "$Base\loras\Lora\Likeness\realisticVaginasGod_sdVSGp1S.safetensors" -Destination "$Base\loras\" -Force
}

# ==============================
# DOWNLOAD CHECKPOINT
# ==============================
Write-Host "`n--- DANG TAI CHECKPOINTS ---" -ForegroundColor Cyan
hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir "$Base\diffusion_models"

# ==============================
# DOWNLOAD CLIP
# ==============================
Write-Host "`n--- DANG TAI CLIP ---" -ForegroundColor Cyan
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir "$Base\clip"
if (Test-Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors") {
    Move-Item -Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors" -Destination "$Base\clip\" -Force
}

# ==============================
# DOWNLOAD VAE
# ==============================
Write-Host "`n--- DANG TAI VAE ---" -ForegroundColor Cyan
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$Base\vae"
if (Test-Path "$Base\vae\split_files\vae\flux2-vae.safetensors") {
    Move-Item -Path "$Base\vae\split_files\vae\flux2-vae.safetensors" -Destination "$Base\vae\" -Force
}

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================
Write-Host "`n--- DANG TAI CAC MODEL BO SUNG (DROPBOX) ---" -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1" -OutFile "$Base\loras\pusfix-klein.safetensors"
Invoke-WebRequest -Uri "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1" -OutFile "$Base\loras\klein_lora_face1.safetensors"

Write-Host "`n✅ Download complete!" -ForegroundColor Green