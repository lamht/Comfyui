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
export HF_HUB_ENABLE_HF_TRANSFER=1 

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
BASE=ComfyUI/models

mkdir -p $BASE/{loras,checkpoints,clip,vae}

# ==============================
# DOWNLOAD LORA
# ==============================
hf download BuckyDroid/test_lora \
  scg-anatomy-female-v2.safetensors \
  --local-dir $BASE/loras

# ==============================
# DOWNLOAD LORA (FACE SWAP)
# ==============================
hf download Alissonerdx/BFS-Best-Face-Swap \
  bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors \
  --local-dir $BASE/loras

# ==============================
# DOWNLOAD CHECKPOINT
# ==============================
hf download black-forest-labs/FLUX.2-klein-9B \
  flux-2-klein-9b.safetensors \
  --local-dir $BASE/checkpoints

# ==============================
# DOWNLOAD CLIP
# ==============================
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b \
  split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors \
  --local-dir $BASE/clip

# ==============================
# DOWNLOAD VAE
# ==============================
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b \
  split_files/vae/flux2-vae.safetensors \
  --local-dir $BASE/vae

echo "✅ Download complete!"