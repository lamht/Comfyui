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

mkdir -p $BASE/{loras,checkpoints,clip,vae}

rm -rf /root/Comfyui/ComfyUI/models/diffusion_models/.cache/huggingface/download/*

# Raw downloads (no existence checks)
# We'll call `hf download` and `wget -O` directly so files are always fetched/overwritten.

# ==============================
# DOWNLOAD LORA
# ==============================
#https://huggingface.co/Aitrepreneur/FLX/blob/main/scg-anatomy-female-v2.safetensors
# hf download Aitrepreneur/FLX scg-anatomy-female-v2.safetensors --local-dir $BASE/loras

#https://huggingface.co/uriel353/flux-female-anatomy/resolve/main/flux-female-anatomy.safetensors?download=true
# hf download uriel353/flux-female-anatomy flux-female-anatomy.safetensors --local-dir $BASE/loras
# v4g1n4, n4k3d

# ==============================
# DOWNLOAD LORA (FACE SWAP)
# ==============================
hf download Alissonerdx/BFS-Best-Face-Swap bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors --local-dir $BASE/loras

hf download ali-vilab/ACE_Plus portrait/comfyui_portrait_lora64.safetensors --local-dir $BASE/loras
# src="$BASE/loras/portrait/comfyui_portrait_lora64.safetensors"
# dst="$BASE/loras/comfyui_portrait_lora64.safetensors"
# if [ -f "$src" ]; then
#   mkdir -p "$(dirname "$dst")"
#   mv "$src" "$dst"
# else
#   echo "[SKIP] $src missing, not moving"
# fi

# hf download ali-vilab/ACE_Plus subject/comfyui_subject_lora16.safetensors --local-dir $BASE/loras
# src="$BASE/loras/subject/comfyui_subject_lora16.safetensors"
# dst="$BASE/loras/comfyui_subject_lora16.safetensors"
# if [ -f "$src" ]; then
#   mkdir -p "$(dirname "$dst")"
#   mv "$src" "$dst"
# else
#   echo "[SKIP] $src missing, not moving"
# fi

#https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/blob/main/Klein-consistency.safetensors
# hf download dx8152/Flux2-Klein-9B-Consistency Klein-consistency.safetensors --local-dir $BASE/loras

#https://huggingface.co/gmp-dev/gmp-lora/blob/1786940ba90ccc3509970d1cb3541b2fccfd3de7/Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors
# hf_download_if_missing "$BASE/loras/realisticVaginasGod_sdVSGp1S.safetensors" gmp-dev/gmp-lora Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors --local-dir $BASE/loras
# src="$BASE/loras/Lora/Likeness/realisticVaginasGod_sdVSGp1S.safetensors"
# dst="$BASE/loras/realisticVaginasGod_sdVSGp1S.safetensors"
# if [ -f "$src" ]; then
#   mkdir -p "$(dirname "$dst")"
#   mv "$src" "$dst"
# else
#   echo "[SKIP] $src missing, not moving"
# fi

# hf download fal/FLUX.2-dev-Turbo \
# flux.2-turbo-lora.safetensors \
# --local-dir $BASE/loras

# ==============================
# DOWNLOAD CHECKPOINT
# ==============================
# hf download black-forest-labs/FLUX.2-klein-9B \
#   flux-2-klein-9b.safetensors \
#   --local-dir $BASE/diffusion_models

#https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors?download=true
hf download black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir $BASE/diffusion_models

#https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-kv-fp8/resolve/main/flux-2-klein-9b-kv-fp8.safetensors?download=true
# hf download black-forest-labs/FLUX.2-klein-9b-kv-fp8 \
#   flux-2-klein-9b-kv-fp8.safetensors \
#   --local-dir $BASE/diffusion_models

#https://huggingface.co/jackzheng/flux-fill-FP8/blob/main/fluxFillFP8_v10.safetensors
# hf download jackzheng/flux-fill-FP8 \
#   fluxFillFP8_v10.safetensors \
#   --local-dir $BASE/diffusion_models
  
# ==============================
# DOWNLOAD CLIP
# ==============================
# DOWNLOAD CLIP
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir $BASE/clip
if [ -f "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" ]; then
  mv "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "$BASE/clip/qwen_3_8b_fp8mixed.safetensors"
fi

#https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true
# hf download comfyanonymous/flux_text_encoders \
#   clip_l.safetensors \
#   --local-dir $BASE/clip

#https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors?download=true
# hf download comfyanonymous/flux_text_encoders \
#   t5xxl_fp16.safetensors \
#   --local-dir $BASE/clip
  
# ==============================
# DOWNLOAD VAE
# ==============================
# DOWNLOAD VAE
hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir $BASE/vae
if [ -f "$BASE/vae/split_files/vae/flux2-vae.safetensors" ]; then
  mv "$BASE/vae/split_files/vae/flux2-vae.safetensors" "$BASE/vae/flux2-vae.safetensors"
fi

#https://huggingface.co/lovis93/testllm/resolve/ed9cf1af7465cebca4649157f118e331cf2a084f/ae.safetensors?download=true
# hf download lovis93/testllm \
#   ae.safetensors \
#   --local-dir $BASE/vae

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================
# https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=0
wget -O "$BASE/loras/klein_lora_face1.safetensors" "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1"

# https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=0
wget -O "$BASE/loras/my_lora_klein_002.safetensors" "https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=1"

# https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=0
wget -O "$BASE/loras/my_lora_klein_004_000000300.safetensors" "https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=1"

# https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=0
wget -O "$BASE/loras/mylora_klein_003_000001250.safetensors" "https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=1"

# https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
wget -O "$BASE/loras/my_lora_klein_004_v2_000001250.safetensors" "https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

# https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
wget -O "$BASE/loras/my_lora_klein_004_v2_000001500.safetensors" "https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

echo "✅ Download complete!"
