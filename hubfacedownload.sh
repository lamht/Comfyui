#!/bin/bash

set -e

# ==============================
# SET TOKEN
# ==============================
# export HF_TOKEN=hf_your_token_here

# ==============================
# INSTALL HF CLI (hf)
# ==============================
curl -LsSf https://hf.co/cli/install.sh | bash

# đảm bảo PATH có hf
export PATH="/root/.local/bin:$PATH"

# tăng tốc download
export HF_XET_HIGH_PERFORMANCE=1

download_model() {
  local model="$1"
  shift

  printf '[INFO] [%s] Starting download: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$model"
  if "$@"; then
    printf '[INFO] [%s] Finished download: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$model"
  else
    local status=$?
    printf '[ERROR] [%s] Download failed (exit %s): %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$status" "$model" >&2
    return "$status"
  fi
}

# ==============================
# LOGIN
# ==============================
if [ -n "$HF_TOKEN" ]; then
  hf auth login --token "$HF_TOKEN"
else
  echo "[WARN] No HF_TOKEN provided, downloading public models only"
fi

# ==============================
# BASE PATH
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$COMFY_PATH" ]; then
    export COMFY_PATH="$SCRIPT_DIR/ComfyUI"
    echo "[INFO] COMFY_PATH set to: $COMFY_PATH"
else
    echo "[INFO] COMFY_PATH already set: $COMFY_PATH"
fi
export BASE="$COMFY_PATH/models"

mkdir -p $BASE/{loras,checkpoints,clip,vae,upscale_models,facerestore_models}

rm -rf /root/Comfyui/ComfyUI/models/diffusion_models/.cache/huggingface/download/*


# 4x UltraSharp
download_model "Kim2091/UltraSharp (4x-UltraSharp.pth)" hf download Kim2091/UltraSharp \
  4x-UltraSharp.pth \
  --local-dir "$BASE/upscale_models"

#https://huggingface.co/BarrenWardo/Upscalers/blob/main/003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth
download_model "BarrenWardo/Upscalers (003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth)" hf download BarrenWardo/Upscalers \
  003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth \
  --local-dir "$BASE/upscale_models"

# Raw downloads (no existence checks)
# We'll call `hf download` and `wget -O` directly so files are always fetched/overwritten.

# ==============================
# DOWNLOAD LORA
# ==============================

# ==============================
# DOWNLOAD LORA (FACE SWAP)
# ==============================
download_model "Alissonerdx/BFS-Best-Face-Swap (bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors)" hf download Alissonerdx/BFS-Best-Face-Swap bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors --local-dir "$BASE/loras"

#https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/blob/main/Flux2-Klein-9B-consistency-V2.safetensors
download_model "dx8152/Flux2-Klein-9B-Consistency (Flux2-Klein-9B-consistency-V2.safetensors)" hf download dx8152/Flux2-Klein-9B-Consistency Flux2-Klein-9B-consistency-V2.safetensors --local-dir "$BASE/loras"

# CodeFormer
download_model "CodeFormer (codeformer.pth)" wget -O "$BASE/facerestore_models/codeformer.pth" \
  "https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth"

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================
# https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=0
download_model "klein_lora_face1.safetensors" wget -O "$BASE/loras/klein_lora_face1.safetensors" "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1"

# https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=0
download_model "my_lora_klein_002.safetensors" wget -O "$BASE/loras/my_lora_klein_002.safetensors" "https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=1"

#https://www.dropbox.com/scl/fi/pox80ulg1hbl8i992ssi5/my_lora_klein_002_v2.safetensors?rlkey=hvc8leq26qnuubh5dcxzvfrev&st=4ylrlte4&dl=0
download_model "my_lora_klein_002_v2.safetensors" wget -O "$BASE/loras/my_lora_klein_002_v2.safetensors" "https://www.dropbox.com/scl/fi/pox80ulg1hbl8i992ssi5/my_lora_klein_002_v2.safetensors?rlkey=hvc8leq26qnuubh5dcxzvfrev&st=4ylrlte4&dl=1"

#https://www.dropbox.com/scl/fi/3flukm0ft73x5tvruabyk/my_lora_klein_002_v3.safetensors?rlkey=5f3p1n5md3wcp0tozz9fe713a&st=xtd288do&dl=0
download_model "my_lora_klein_002_v3.safetensors" wget -O "$BASE/loras/my_lora_klein_002_v3.safetensors" "https://www.dropbox.com/scl/fi/3flukm0ft73x5tvruabyk/my_lora_klein_002_v3.safetensors?rlkey=5f3p1n5md3wcp0tozz9fe713a&st=xtd288do&dl=1"

# https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=0
download_model "my_lora_klein_004_000000300.safetensors" wget -O "$BASE/loras/my_lora_klein_004_000000300.safetensors" "https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=1"

# https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=0
download_model "mylora_klein_003_000001250.safetensors" wget -O "$BASE/loras/mylora_klein_003_000001250.safetensors" "https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=1"

# https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
download_model "my_lora_klein_004_v2_000001250.safetensors" wget -O "$BASE/loras/my_lora_klein_004_v2_000001250.safetensors" "https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

# https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
download_model "my_lora_klein_004_v2_000001500.safetensors" wget -O "$BASE/loras/my_lora_klein_004_v2_000001500.safetensors" "https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

# https://www.dropbox.com/scl/fi/yncraovi7yzrlcdparsbf/flux2_lora005.safetensors?rlkey=ad7mynauat1f51r0e0u296h2u&st=v0hovn0e&dl=0
download_model "flux2_lora005.safetensors" wget -O "$BASE/loras/flux2_lora005.safetensors" "https://www.dropbox.com/scl/fi/yncraovi7yzrlcdparsbf/flux2_lora005.safetensors?rlkey=ad7mynauat1f51r0e0u296h2u&st=v0hovn0e&dl=1"

#https://www.dropbox.com/scl/fi/p8710w6fydmj9023v1ui3/realistic.safetensors?rlkey=jvq2qylwuyxbjqkqnwa8ukiux&st=ykpssn2f&dl=0
download_model "realistic.safetensors" wget -O "$BASE/loras/realistic.safetensors" "https://www.dropbox.com/scl/fi/p8710w6fydmj9023v1ui3/realistic.safetensors?rlkey=jvq2qylwuyxbjqkqnwa8ukiux&st=ykpssn2f&dl=1"


# ==============================
# DOWNLOAD CHECKPOINT
# ==============================

#https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors?download=true
echo "Downloading flux-2-klein-9b-fp8.safetensors"
download_model "black-forest-labs/FLUX.2-klein-9b-fp8 (flux-2-klein-9b-fp8.safetensors)" hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir "$BASE/diffusion_models"

# ==============================
# DOWNLOAD CLIP
# ==============================
echo "Downloading qwen_3_8b_fp8mixed.safetensors"
download_model "Comfy-Org/vae-text-encorder-for-flux-klein-9b (qwen_3_8b_fp8mixed.safetensors)" hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir "$BASE/clip"
if [ -f "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" ]; then
  mv "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "$BASE/clip/qwen_3_8b_fp8mixed.safetensors"
fi  
# ==============================
# DOWNLOAD VAE
# ==============================
echo "Downloading flux2-vae.safetensors"
download_model "Comfy-Org/vae-text-encorder-for-flux-klein-9b (flux2-vae.safetensors)" hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$BASE/vae"
if [ -f "$BASE/vae/split_files/vae/flux2-vae.safetensors" ]; then
  mv "$BASE/vae/split_files/vae/flux2-vae.safetensors" "$BASE/vae/flux2-vae.safetensors"
fi

echo "✅ Download complete!"
