#!/bin/bash

set -e
set -o pipefail

# ==============================
# SET TOKEN
# ==============================
# export HF_TOKEN=hf_your_token_here

# ==============================
# INSTALL HF CLI (hf)
# ==============================
# đảm bảo PATH có hf
export PATH="/root/.local/bin:$PATH"

if ! command -v hf >/dev/null 2>&1; then
  curl -LsSf https://hf.co/cli/install.sh | bash
fi

## INSTALLATION GDOWN (Colab only)
if [ "${COLAB:-}" = "1" ] && ! command -v gdown >/dev/null 2>&1; then
  pip install -q gdown
fi

# tăng tốc download
export HF_XET_HIGH_PERFORMANCE=1

download_model() {
  local model="$1"
  shift

  local start_time end_time elapsed status target=""

  if [ "$1" = "hf" ] && [ "$2" = "download" ]; then
    local local_dir="" requested_file="" expect_local_dir=0 argument_index=0
    for arg in "$@"; do
      argument_index=$((argument_index + 1))
      if [ "$argument_index" -le 3 ]; then
        continue
      fi
      if [ "$expect_local_dir" = "1" ]; then
        local_dir="$arg"
        expect_local_dir=0
      elif [ "$arg" = "--local-dir" ]; then
        expect_local_dir=1
      elif [[ "$arg" != -* ]] && [ -z "$requested_file" ]; then
        requested_file="$arg"
      fi
    done
    if [ -n "$local_dir" ] && [ -n "$requested_file" ]; then
      target="$local_dir/$requested_file"
      if [[ "$requested_file" == split_files/* ]]; then
        local relocated_target="$local_dir/${requested_file##*/}"
        if [ -s "$relocated_target" ]; then
          target="$relocated_target"
        fi
      fi
    fi
  else
    local previous=""
    for arg in "$@"; do
      if [ "$previous" = "-O" ]; then
        target="$arg"
        break
      fi
      previous="$arg"
    done
  fi

  if [ -n "$target" ] && [ -s "$target" ]; then
    printf '[INFO] [%s] Skipping existing file: %s\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "$target"
    return 0
  fi

  start_time=$(date +%s)

  printf '[INFO] [%s] Starting download: %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$model"

  if "$@"; then
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))

    printf '[INFO] [%s] Finished download: %s (Time: %02d:%02d:%02d)\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" \
      "$model" \
      "$((elapsed / 3600))" \
      "$(((elapsed % 3600) / 60))" \
      "$((elapsed % 60))"
  else
    status=$?
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))

    printf '[ERROR] [%s] Download failed (exit %s): %s (Elapsed: %02d:%02d:%02d)\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" \
      "$status" "$model" \
      "$((elapsed / 3600))" \
      "$(((elapsed % 3600) / 60))" \
      "$((elapsed % 60))" >&2

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

mkdir -p "$BASE/loras" "$BASE/checkpoints" "$BASE/clip" "$BASE/vae" "$BASE/upscale_models" "$BASE/facerestore_models"

# ==============================
# DOWNLOAD LORA
# ==============================

# ==============================
# DOWNLOAD ADDITIONAL MODELS
# ==============================

#https://www.dropbox.com/scl/fi/ys7df7zfiufa31ggktcdf/krea2_odi_krea2_V1.safetensors?rlkey=2rn859lxrexgu0dtvvuvguz37&st=vyri6ru3&dl=0
download_model "krea2_odi_krea2_V1.safetensors" wget -O "$BASE/loras/krea2_odi_krea2_V1.safetensors" "https://www.dropbox.com/scl/fi/ys7df7zfiufa31ggktcdf/krea2_odi_krea2_V1.safetensors?rlkey=2rn859lxrexgu0dtvvuvguz37&st=vyri6ru3&dl=1"

#https://www.dropbox.com/scl/fi/oyjl1f6axg6lu3nyr04ie/krea2_identity_edit_v2_r128.safetensors?rlkey=93yw5anjjgly0piyb0t6bmzua&st=d0ies4it&dl=0
download_model "krea2_identity_edit_v2_r128.safetensors" wget -O "$BASE/loras/krea2_identity_edit_v2_r128.safetensors" "https://www.dropbox.com/scl/fi/oyjl1f6axg6lu3nyr04ie/krea2_identity_edit_v2_r128.safetensors?rlkey=93yw5anjjgly0piyb0t6bmzua&st=d0ies4it&dl=1"

#https://www.dropbox.com/scl/fi/95dse9le52idxbtwsq93d/krea2_pretty_odi_v2.safetensors?rlkey=p2ucb0sx65j9p009aihj3g369&st=g3ollcap&dl=0
download_model "krea2_pretty_odi_v2.safetensors" wget -O "$BASE/loras/krea2_pretty_odi_v2.safetensors" "https://www.dropbox.com/scl/fi/95dse9le52idxbtwsq93d/krea2_pretty_odi_v2.safetensors?rlkey=p2ucb0sx65j9p009aihj3g369&st=g3ollcap&dl=1"

#https://www.dropbox.com/scl/fi/4tbklc8dhbijs0pz14a9b/Krea2_spread_odi.safetensors?rlkey=uresac2gggw89ycyd5hbxo04o&st=uo69zn9i&dl=0
download_model "Krea2_spread_odi.safetensors" wget -O "$BASE/loras/Krea2_spread_odi.safetensors" "https://www.dropbox.com/scl/fi/4tbklc8dhbijs0pz14a9b/Krea2_spread_odi.safetensors?rlkey=uresac2gggw89ycyd5hbxo04o&st=uo69zn9i&dl=1"


# =========================================================
# DOWNLOAD KREA 2 TURBO FP8
# =========================================================

    # -----------------------------------------------------
    # PATHS
    # -----------------------------------------------------

    BASE="${BASE:-/app/ComfyUI/models}"

    DIFFUSION_DIR="$BASE/diffusion_models"
    CLIP_DIR="$BASE/text_encoders"
    VAE_DIR="$BASE/vae"

    mkdir -p "$DIFFUSION_DIR" "$CLIP_DIR" "$VAE_DIR"

    # -----------------------------------------------------
    # 1. DIFFUSION MODEL
    # -----------------------------------------------------

    echo "Downloading krea2_turbo_fp8_scaled.safetensors"

    download_model "KREA 2 Turbo FP8" \
      hf download Comfy-Org/Krea-2 \
      diffusion_models/krea2_turbo_fp8_scaled.safetensors \
      --local-dir "$BASE"

    # -----------------------------------------------------
    # 2. CLIP / TEXT ENCODER
    # -----------------------------------------------------

    echo "Downloading qwen3vl_4b_fp8_scaled.safetensors"

    download_model "KREA 2 Qwen3 VL 4B FP8" \
      hf download Comfy-Org/Krea-2 \
      text_encoders/qwen3vl_4b_fp8_scaled.safetensors \
      --local-dir "$BASE"

    # -----------------------------------------------------
    # 3. VAE
    # -----------------------------------------------------

    echo "Downloading qwen_image_vae.safetensors"

    download_model "KREA 2 Qwen Image VAE" \
      hf download Comfy-Org/Krea-2 \
      vae/qwen_image_vae.safetensors \
      --local-dir "$BASE"

    echo "[INFO] KREA 2 Turbo FP8 download completed"


echo "✅ Download complete!"
