#!/bin/bash

set -e
export PATH="$HOME/.local/bin:$PATH"

# speed up downloads
export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_XET_HIGH_PERFORMANCE=1

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
export BASE="$(dirname "$0")/ComfyUI/models"

mkdir -p "$BASE/clip" "$BASE/vae" "$BASE/diffusion_models"

rm -rf "$BASE/diffusion_models/.cache/huggingface/download"/* 2>/dev/null || true

# download CLIP
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir "$BASE/clip"
if [ -f "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" ]; then
  mv "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "$BASE/clip/qwen_3_8b_fp8mixed.safetensors"
fi

# download VAE
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir "$BASE/vae"
if [ -f "$BASE/vae/split_files/vae/flux2-vae.safetensors" ]; then
  mv "$BASE/vae/split_files/vae/flux2-vae.safetensors" "$BASE/vae/flux2-vae.safetensors"
fi

# download checkpoint
hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir "$BASE/diffusion_models"

echo "✅ VAE, CLIP, and checkpoint download complete!"
