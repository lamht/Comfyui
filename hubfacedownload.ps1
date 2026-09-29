$ErrorActionPreference = "Stop"

# ==============================
# SET TOKEN
# ==============================
# $env:HF_TOKEN = "hf_your_token_here"

# Tăng tốc download
$env:HF_XET_HIGH_PERFORMANCE = "1"
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"

# ==============================
# LOGIN
# ==============================
if ([bool]$env:HF_TOKEN) {
    hf auth login --token $env:HF_TOKEN
} else {
    Write-Host "[WARN] No HF_TOKEN provided, downloading public models only" -ForegroundColor Yellow
}

# ==============================
# BASE PATH
# ==============================
if ($env:COMFY_PATH) {
    Write-Host "[INFO] COMFY_PATH already set: $env:COMFY_PATH" -ForegroundColor Cyan
} else {
    $env:COMFY_PATH = [System.IO.Path]::Combine($PSScriptRoot, "ComfyUI")
    Write-Host "[INFO] COMFY_PATH set to: $env:COMFY_PATH" -ForegroundColor Cyan
}

$Base = [System.IO.Path]::Combine($env:COMFY_PATH, "models")

# Tạo thư mục nếu chưa tồn tại
$SubDirs = @("loras", "checkpoints", "clip", "vae", "upscale_models", "facerestore_models", "diffusion_models")
foreach ($Dir in $SubDirs) {
    $TargetDir = Join-Path $Base $Dir
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
}

# Xóa cache
$CachePath = "$Base\diffusion_models\.cache\huggingface\download\*"
if (Test-Path $CachePath) {
    Remove-Item -Path $CachePath -Recurse -Force -ErrorAction SilentlyContinue
}

# ==============================
# DOWNLOAD LORA (FACE SWAP & CONSISTENCY)
# ==============================
Write-Host "`n--- DOWNLOADING LORAS ---" -ForegroundColor Cyan
hf download Alissonerdx/BFS-Best-Face-Swap bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors --local-dir "$Base\loras"
hf download ali-vilab/ACE_Plus portrait/comfyui_portrait_lora64.safetensors --local-dir "$Base\loras"
hf download dx8152/Flux2-Klein-9B-Consistency Flux2-Klein-9B-consistency-V2.safetensors --local-dir "$Base\loras"

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
    Move-Item -Path "$Base\clip\split_files\text_encoders\qwen_3_8b_fp8mixed.safetensors" -Destination "$Base\clip\qwen_3_8b_fp8mixed.safetensors" -Force
}

# ==============================
# DOWNLOAD VAE
# ==============================
Write-Host "`n--- DOWNLOADING VAE ---" -ForegroundColor Cyan
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$Base\vae"
if (Test-Path "$Base\vae\split_files\vae\flux2-vae.safetensors") {
    Move-Item -Path "$Base\vae\split_files\vae\flux2-vae.safetensors" -Destination "$Base\vae\flux2-vae.safetensors" -Force
}

# ==============================
# DOWNLOAD UPSCALE & FACERESTORE
# ==============================
Write-Host "`n--- DOWNLOADING UPSCALE & FACERESTORE ---" -ForegroundColor Cyan
hf download Kim2091/UltraSharp 4x-UltraSharp.pth --local-dir "$Base\upscale_models"
curl.exe -L --create-dirs -o "$Base\facerestore_models\codeformer.pth" "https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth"

# ==============================
# DOWNLOAD ADDITIONAL MODELS FROM DROPBOX
# ==============================
Write-Host "`n--- DOWNLOADING ADDITIONAL MODELS FROM DROPBOX ---" -ForegroundColor Cyan
$DropboxFiles = @(
    @{ Out = "klein_lora_face1.safetensors"; Url = "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1" },
    @{ Out = "my_lora_klein_002.safetensors"; Url = "https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=1" },
    @{ Out = "my_lora_klein_002_v2.safetensors"; Url = "https://www.dropbox.com/scl/fi/pox80ulg1hbl8i992ssi5/my_lora_klein_002_v2.safetensors?rlkey=hvc8leq26qnuubh5dcxzvfrev&st=4ylrlte4&dl=1" },
    @{ Out = "my_lora_klein_004_000000300.safetensors"; Url = "https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=1" },
    @{ Out = "mylora_klein_003_000001250.safetensors"; Url = "https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=1" },
    @{ Out = "my_lora_klein_004_v2_000001250.safetensors"; Url = "https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1" },
    @{ Out = "my_lora_klein_004_v2_000001500.safetensors"; Url = "https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1" },
    @{ Out = "flux2_lora005.safetensors"; Url = "https://www.dropbox.com/scl/fi/yncraovi7yzrlcdparsbf/flux2_lora005.safetensors?rlkey=ad7mynauat1f51r0e0u296h2u&st=v0hovn0e&dl=1" },
    @{ Out = "realistic.safetensors"; Url = "https://www.dropbox.com/scl/fi/p8710w6fydmj9023v1ui3/realistic.safetensors?rlkey=jvq2qylwuyxbjqkqnwa8ukiux&st=ykpssn2f&dl=1" }
)

foreach ($Item in $DropboxFiles) {
    $OutPath = Join-Path $Base "loras\$($Item.Out)"
    curl.exe -L --create-dirs -o $OutPath $Item.Url
}

Write-Host "`n✅ Download complete!" -ForegroundColor Green