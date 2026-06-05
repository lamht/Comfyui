$ErrorActionPreference = "Stop"

# ==============================
# SET TOKEN
# ==============================
# $env:HF_TOKEN = "hf_your_token_here"

# ==============================
# CHOOSE PATH
# ==============================
$Base = Join-Path $PSScriptRoot "models"

# Create directories if they do not exist
$SubDirs = @("loras", "checkpoints", "clip", "vae", "diffusion_models")
foreach ($Dir in $SubDirs) {
    $TargetDir = Join-Path $Base $Dir
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
}

# Tăng tốc download bằng hf_transfer nếu đã cài
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"

# ==============================
# DOWNLOAD LORA
# ==============================
Write-Host "`n--- DOWNLOADING LORAS ---" -ForegroundColor Cyan

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
Write-Host "`n--- DOWNLOADING CHECKPOINTS ---" -ForegroundColor Cyan
hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir "$Base\diffusion_models"

# ==============================
# DOWNLOAD CLIP
# ==============================
Write-Host "`n--- DOWNLOADING CLIP ---" -ForegroundColor Cyan
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir "$Base\clip"
if (Test-Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors") {
    Move-Item -Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors" -Destination "$Base\clip\" -Force
}

# ==============================
# DOWNLOAD VAE
# ==============================
Write-Host "`n--- DOWNLOADING VAE ---" -ForegroundColor Cyan
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$Base\vae"
if (Test-Path "$Base\vae\split_files\vae\flux2-vae.safetensors") {
    Move-Item -Path "$Base\vae\split_files\vae\flux2-vae.safetensors" -Destination "$Base\vae\" -Force
}

# ==============================
# DOWNLOAD ADDITIONAL MODELS (DROPBOX)
# ==============================
Write-Host "`n--- DOWNLOADING ADDITIONAL MODELS FROM DROPBOX ---" -ForegroundColor Cyan

$DropboxUrl1 = 'https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1'
Invoke-WebRequest -Uri $DropboxUrl1 -OutFile "$Base\loras\pusfix-klein.safetensors"

$DropboxUrl2 = 'https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1'
Invoke-WebRequest -Uri $DropboxUrl2 -OutFile "$Base\loras\klein_lora_face1.safetensors"

Write-Host "`n[SUCCESS] Download complete!" -ForegroundColor Green