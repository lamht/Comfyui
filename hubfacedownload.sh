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

# Helper: download with existence check for `hf download`
hf_download_if_missing() {
  dest="$1"
  shift
  if [ -f "$dest" ]; then
    echo "[SKIP] $dest exists"
  else
    hf download "$@"
  fi
}

# Helper: download with existence check for `wget -O`
wget_if_missing() {
  dest="$1"
  url="$2"
  if [ -f "$dest" ]; then
    echo "[SKIP] $dest exists"
  else
    wget -O "$dest" "$url"
  fi
}

# ==============================
# DOWNLOAD LORA
# ==============================
#https://huggingface.co/Aitrepreneur/FLX/blob/main/scg-anatomy-female-v2.safetensors
hf_download_if_missing "$BASE/loras/scg-anatomy-female-v2.safetensors" Aitrepreneur/FLX scg-anatomy-female-v2.safetensors --local-dir $BASE/loras

#https://huggingface.co/uriel353/flux-female-anatomy/resolve/main/flux-female-anatomy.safetensors?download=true
hf_download_if_missing "$BASE/loras/flux-female-anatomy.safetensors" uriel353/flux-female-anatomy flux-female-anatomy.safetensors --local-dir $BASE/loras
# v4g1n4, n4k3d

# ==============================
# DOWNLOAD LORA (FACE SWAP)
# ==============================
hf_download_if_missing "$BASE/loras/bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors" Alissonerdx/BFS-Best-Face-Swap bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors --local-dir $BASE/loras

hf_download_if_missing "$BASE/loras/comfyui_portrait_lora64.safetensors" ali-vilab/ACE_Plus portrait/comfyui_portrait_lora64.safetensors --local-dir $BASE/loras
src="$BASE/loras/portrait/comfyui_portrait_lora64.safetensors"
dst="$BASE/loras/comfyui_portrait_lora64.safetensors"
if [ -f "$src" ]; then
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
else
  echo "[SKIP] $src missing, not moving"
fi

hf_download_if_missing "$BASE/loras/comfyui_subject_lora16.safetensors" ali-vilab/ACE_Plus subject/comfyui_subject_lora16.safetensors --local-dir $BASE/loras
src="$BASE/loras/subject/comfyui_subject_lora16.safetensors"
dst="$BASE/loras/comfyui_subject_lora16.safetensors"
if [ -f "$src" ]; then
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
else
  echo "[SKIP] $src missing, not moving"
fi

#https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/blob/main/Klein-consistency.safetensors
hf_download_if_missing "$BASE/loras/Klein-consistency.safetensors" dx8152/Flux2-Klein-9B-Consistency Klein-consistency.safetensors --local-dir $BASE/loras

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
hf_download_if_missing "$BASE/diffusion_models/flux-2-klein-9b-fp8.safetensors" black-forest-labs/FLUX.2-klein-9b-fp8 flux-2-klein-9b-fp8.safetensors --local-dir $BASE/diffusion_models

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
hf_download_if_missing "$BASE/clip/qwen_3_8b_fp8mixed.safetensors" Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors --local-dir $BASE/clip
src="$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"
dst="$BASE/clip/qwen_3_8b_fp8mixed.safetensors"
if [ -f "$src" ]; then
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
else
  echo "[SKIP] $src missing, not moving"
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
hf_download_if_missing "$BASE/vae/flux2-vae.safetensors" Comfy-Org/vae-text-encorder-for-flux-klein-9b split_files/vae/flux2-vae.safetensors --local-dir $BASE/vae
src="$BASE/vae/split_files/vae/flux2-vae.safetensors"
dst="$BASE/vae/flux2-vae.safetensors"
if [ -f "$src" ]; then
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
else
  echo "[SKIP] $src missing, not moving"
fi

#https://huggingface.co/lovis93/testllm/resolve/ed9cf1af7465cebca4649157f118e331cf2a084f/ae.safetensors?download=true
# hf download lovis93/testllm \
#   ae.safetensors \
#   --local-dir $BASE/vae

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================
# https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=0
wget_if_missing "$BASE/loras/pusfix-klein.safetensors" "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1"

# https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=0
wget_if_missing "$BASE/loras/klein_lora_face1.safetensors" "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1"

# https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=0
wget_if_missing "$BASE/loras/my_lora_klein_002.safetensors" "https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=1"
echo "✅ Download complete!"
