#!/bin/bash

set -euo pipefail

if [ -z "${HF_TOKEN:-}" ]; then
  echo "[WARN] HF_TOKEN is not set; public downloads only"
  AUTH_ARGS=()
else
  AUTH_ARGS=(--header="Authorization: Bearer ${HF_TOKEN}")
fi

BASE="$(dirname "$0")/ComfyUI/models"
mkdir -p "$BASE"/{loras,diffusion_models,clip,vae}

download() {
  local url="$1"
  local dst="$2"
  echo "Downloading $dst"
  wget -c "${AUTH_ARGS[@]}" -O "$dst" "$url"
}

# Hugging Face downloads
# LORA
download "https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors" "$BASE/loras/bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors"
download "https://huggingface.co/ali-vilab/ACE_Plus/resolve/main/portrait/comfyui_portrait_lora64.safetensors" "$BASE/loras/comfyui_portrait_lora64.safetensors"

# Checkpoint
download "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" "$BASE/diffusion_models/flux-2-klein-9b-fp8.safetensors"

# CLIP
download "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "$BASE/clip/qwen_3_8b_fp8mixed.safetensors"

# VAE
download "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/vae/flux2-vae.safetensors" "$BASE/vae/flux2-vae.safetensors"

# Additional existing downloads
wget -c -O "$BASE/loras/pusfix-klein.safetensors" "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=oj9yimns&dl=1"
wget -c -O "$BASE/loras/klein_lora_face1.safetensors" "https://www.dropbox.com/scl/fi/joh1wnos385ynomj49x8e/klein_lora_face1.safetensors?rlkey=xnb5uee5sklpza56pup0jtdt2&st=7sscwh2r&dl=1"
wget -c -O "$BASE/loras/my_lora_klein_002.safetensors" "https://www.dropbox.com/scl/fi/prvqc30iqqgk12e8x5iyw/my_lora_klein_002.safetensors?rlkey=fq0wznag4ufbb38u8pb2zggsj&st=u3q10jwr&dl=1"
wget -c -O "$BASE/loras/my_lora_klein_004_000000300.safetensors" "https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=1"
wget -c -O "$BASE/loras/mylora_klein_003_000001250.safetensors" "https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=1"

echo "✅ Download complete!"
