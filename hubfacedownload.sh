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

## INSTALLATION GDOWN (Colab only)
if [ "${COLAB:-}" = "1" ] && ! command -v gdown >/dev/null 2>&1; then
  pip install -q gdown
fi

# đảm bảo PATH có hf
export PATH="/root/.local/bin:$PATH"

# tăng tốc download
export HF_XET_HIGH_PERFORMANCE=1

download_model() {
  local model="$1"
  shift

  local start_time end_time elapsed status

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

HF_CACHE_DIR="$COMFY_PATH/models/diffusion_models/.cache/huggingface/download"
if [ -d "$HF_CACHE_DIR" ]; then
  rm -rf "$HF_CACHE_DIR"/*
fi

# 4x UltraSharp
download_model "Kim2091/UltraSharp (4x-UltraSharp.pth)" hf download Kim2091/UltraSharp \
  4x-UltraSharp.pth \
  --local-dir "$BASE/upscale_models"

#https://huggingface.co/BarrenWardo/Upscalers/blob/main/003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth
download_model "BarrenWardo/Upscalers (003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth)" hf download BarrenWardo/Upscalers \
  003_realSR_BSRGAN_DFOWMFC_s64w8_SwinIR-L_x4_GAN.pth \
  --local-dir "$BASE/upscale_models"

# https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/blob/main/4x_foolhardy_Remacri.pth
download_model "FacehugmanIII/4x_foolhardy_Remacri (4x_foolhardy_Remacri.pth)" hf download FacehugmanIII/4x_foolhardy_Remacri \
  4x_foolhardy_Remacri.pth \
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

#https://www.dropbox.com/scl/fi/3flukm0ft73x5tvruabyk/my_lora_klein_002_v3.safetensors?rlkey=5f3p1n5md3wcp0tozz9fe713a&st=xtd288do&dl=0
download_model "my_lora_klein_002_v3.safetensors" wget -O "$BASE/loras/my_lora_klein_002_v3.safetensors" "https://www.dropbox.com/scl/fi/3flukm0ft73x5tvruabyk/my_lora_klein_002_v3.safetensors?rlkey=5f3p1n5md3wcp0tozz9fe713a&st=xtd288do&dl=1"

#https://www.dropbox.com/scl/fi/17zg9vmp5onzzg13erza7/mylora_klein_002_v4_500.safetensors?rlkey=hn50hutqy58kcqt7rv4o52nz5&st=5xzoc9zg&dl=0
download_model "mylora_klein_002_v4_500.safetensors" wget -O "$BASE/loras/mylora_klein_002_v4_500.safetensors" "https://www.dropbox.com/scl/fi/17zg9vmp5onzzg13erza7/mylora_klein_002_v4_500.safetensors?rlkey=hn50hutqy58kcqt7rv4o52nz5&st=5xzoc9zg&dl=1"

#https://www.dropbox.com/scl/fi/bk3fydes62owf9p7red7d/mylora_klein_003.safetensors?rlkey=o1og3d1iw2mh6e62wa63dp477&st=8rpznx5d&dl=0
download_model "mylora_klein_003.safetensors" wget -O "$BASE/loras/mylora_klein_003.safetensors" "https://www.dropbox.com/scl/fi/bk3fydes62owf9p7red7d/mylora_klein_003.safetensors?rlkey=o1og3d1iw2mh6e62wa63dp477&st=8rpznx5d&dl=1"

# https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=0
download_model "my_lora_klein_004_000000300.safetensors" wget -O "$BASE/loras/my_lora_klein_004_000000300.safetensors" "https://www.dropbox.com/scl/fi/lew172dl9zaygl17wgvqv/my_lora_klein_004_000000300.safetensors?rlkey=0hbw51g0j3kjcvgjxecag4oc6&st=7zu7mowi&dl=1"

# https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=0
download_model "mylora_klein_003_000001250.safetensors" wget -O "$BASE/loras/mylora_klein_003_000001250.safetensors" "https://www.dropbox.com/scl/fi/vftvcrsdkv2w0gru8rg0e/mylora_klein_003_000001250.safetensors?rlkey=i4pv7muazvsyuu95xqucmryhi&st=zltv03vi&dl=1"

# https://www.dropbox.com/scl/fi/s31598pqvn6ta8n7xs5ny/mylora_klein_003_v2.safetensors?rlkey=x23rzbzlaxchbtzh6pphi1u8w&st=aexasb06&dl=0
download_model "mylora_klein_003_v2.safetensors" wget -O "$BASE/loras/mylora_klein_003_v2.safetensors" "https://www.dropbox.com/scl/fi/s31598pqvn6ta8n7xs5ny/mylora_klein_003_v2.safetensors?rlkey=x23rzbzlaxchbtzh6pphi1u8w&st=aexasb06&dl=1"

#https://www.dropbox.com/scl/fi/0amzv29fwuqohyuw1cv7k/mylora_klein_003_v3_000002200.safetensors?rlkey=xgr6ub84ufcmvdqcxxdeteh3a&st=1bdwinw1&dl=0
download_model "mylora_klein_003_v3_000002200.safetensors" wget -O "$BASE/loras/mylora_klein_003_v3_000002200.safetensors" "https://www.dropbox.com/scl/fi/0amzv29fwuqohyuw1cv7k/mylora_klein_003_v3_000002200.safetensors?rlkey=xgr6ub84ufcmvdqcxxdeteh3a&st=1bdwinw1&dl=1"

#https://www.dropbox.com/scl/fi/8msnw9ovc2b6idl7708ac/mylora_klein_003_v3_000002400.safetensors?rlkey=5k6nsxec85b066amod31sxam1&st=juxgsxkt&dl=0
download_model "mylora_klein_003_v3_000002400.safetensors" wget -O "$BASE/loras/mylora_klein_003_v3_000002400.safetensors" "https://www.dropbox.com/scl/fi/8msnw9ovc2b6idl7708ac/mylora_klein_003_v3_000002400.safetensors?rlkey=5k6nsxec85b066amod31sxam1&st=juxgsxkt&dl=1"

#https://www.dropbox.com/scl/fi/p89nork7ozmitcy8gbicw/flux3_003_v1_00000750.safetensors?rlkey=e9fgwwhnjjpmqurzl5h15s8an&st=xlwiy06x&dl=0
download_model "flux3_003_v1_00000750.safetensors" wget -O "$BASE/loras/flux3_003_v1_00000750.safetensors" "https://www.dropbox.com/scl/fi/p89nork7ozmitcy8gbicw/flux3_003_v1_00000750.safetensors?rlkey=e9fgwwhnjjpmqurzl5h15s8an&st=xlwiy06x&dl=1"

#https://www.dropbox.com/scl/fi/kyoofycjxvk7pwy9agugq/flux3_003_v1_00001000.safetensors?rlkey=04h4hxt6d6u6rk05puwdces8a&st=lzekfrb4&dl=0
download_model "flux3_003_v1_00001000.safetensors" wget -O "$BASE/loras/flux3_003_v1_00001000.safetensors" "https://www.dropbox.com/scl/fi/kyoofycjxvk7pwy9agugq/flux3_003_v1_00001000.safetensors?rlkey=04h4hxt6d6u6rk05puwdces8a&st=lzekfrb4&dl=1"

#https://www.dropbox.com/scl/fi/e3mj3r26agly8gv3i6jx8/flux3_003_v1_000001250.safetensors?rlkey=xiatw1m0wxdfnwtkhqoul211z&st=1052g158&dl=0
download_model "flux3_003_v1_000001250.safetensors" wget -O "$BASE/loras/flux3_003_v1_000001250.safetensors" "https://www.dropbox.com/scl/fi/e3mj3r26agly8gv3i6jx8/flux3_003_v1_000001250.safetensors?rlkey=xiatw1m0wxdfnwtkhqoul211z&st=1052g158&dl=1"

#https://www.dropbox.com/scl/fi/lqihsip4kj2qot1w88ykd/flux3_003_v1_00001500.safetensors?rlkey=f2c9k3thtjspiuggaqjygpqc6&st=e1mfu2zd&dl=0
download_model "flux3_003_v1_00001500.safetensors" wget -O "$BASE/loras/flux3_003_v1_00001500.safetensors" "https://www.dropbox.com/scl/fi/lqihsip4kj2qot1w88ykd/flux3_003_v1_00001500.safetensors?rlkey=f2c9k3thtjspiuggaqjygpqc6&st=e1mfu2zd&dl=1"

# https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
download_model "my_lora_klein_004_v2_000001250.safetensors" wget -O "$BASE/loras/my_lora_klein_004_v2_000001250.safetensors" "https://www.dropbox.com/scl/fi/6nvl483ugp9mwlllg2w04/my_lora_klein_004_v2_000001250.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

# https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=0
download_model "my_lora_klein_004_v2_000001500.safetensors" wget -O "$BASE/loras/my_lora_klein_004_v2_000001500.safetensors" "https://www.dropbox.com/scl/fi/0x1g6j7q3k5v8y4x9z0b/my_lora_klein_004_v2_000001500.safetensors?rlkey=42r12ptupfdghehsw0t2o00xz&st=tp2ldcew&dl=1"

# https://www.dropbox.com/scl/fi/yncraovi7yzrlcdparsbf/flux2_lora005.safetensors?rlkey=ad7mynauat1f51r0e0u296h2u&st=v0hovn0e&dl=0
download_model "flux2_lora005.safetensors" wget -O "$BASE/loras/flux2_lora005.safetensors" "https://www.dropbox.com/scl/fi/yncraovi7yzrlcdparsbf/flux2_lora005.safetensors?rlkey=ad7mynauat1f51r0e0u296h2u&st=v0hovn0e&dl=1"

#https://www.dropbox.com/scl/fi/p8710w6fydmj9023v1ui3/realistic.safetensors?rlkey=jvq2qylwuyxbjqkqnwa8ukiux&st=ykpssn2f&dl=0
download_model "realistic.safetensors" wget -O "$BASE/loras/realistic.safetensors" "https://www.dropbox.com/scl/fi/p8710w6fydmj9023v1ui3/realistic.safetensors?rlkey=jvq2qylwuyxbjqkqnwa8ukiux&st=ykpssn2f&dl=1"

#https://www.dropbox.com/scl/fi/r26bci7di5ahb0a0ozzbi/klein_slider_anatomy.safetensors?rlkey=qcbui3mu8bu3glabfglzbvc4g&st=noezq1pg&dl=0
download_model "klein_slider_anatomy.safetensors" wget -O "$BASE/loras/klein_slider_anatomy.safetensors" "https://www.dropbox.com/scl/fi/r26bci7di5ahb0a0ozzbi/klein_slider_anatomy.safetensors?rlkey=qcbui3mu8bu3glabfglzbvc4g&st=noezq1pg&dl=1"

#https://www.dropbox.com/scl/fi/yua972eitb209gg6u8j1x/Flux2209B20DetaiLoRA.safetensors?rlkey=m633gvgvykhclg3igq0to3kzb&st=4uxh61jh&dl=0
download_model "Flux2209B20DetaiLoRA.safetensors" wget -O "$BASE/loras/Flux2209B20DetaiLoRA.safetensors" "https://www.dropbox.com/scl/fi/yua972eitb209gg6u8j1x/Flux2209B20DetaiLoRA.safetensors?rlkey=m633gvgvykhclg3igq0to3kzb&st=4uxh61jh&dl=1"

#https://www.dropbox.com/scl/fi/ybxpghxzdg6fhtdng2e4a/f2k_9B_lcs_consist_preview.safetensors?rlkey=mt5hf1opewv89bskw838t17i7&st=2zhlzry6&dl=0
download_model "f2k_9B_lcs_consist_preview.safetensors" wget -O "$BASE/loras/f2k_9B_lcs_consist_preview.safetensors" "https://www.dropbox.com/scl/fi/ybxpghxzdg6fhtdng2e4a/f2k_9B_lcs_consist_preview.safetensors?rlkey=mt5hf1opewv89bskw838t17i7&st=2zhlzry6&dl=1"

#https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=z7g744vu&dl=0
download_model "pusfix-klein.safetensors" wget -O "$BASE/loras/pusfix-klein.safetensors" "https://www.dropbox.com/scl/fi/pws3t2zqx6597fuy2darh/pusfix-klein.safetensors?rlkey=3fooobe4nawbn3ttisl50zt9n&st=z7g744vu&dl=1"

#https://www.dropbox.com/scl/fi/qkdbb5nsjammi4gp0hfo1/flux-2-klein-9b_odi_V1.safetensors?rlkey=ixajje8wpyuzw1s4kxvjurslc&st=vm58nmrr&dl=0
download_model "flux-2-klein-9b_odi_V1.safetensors" wget -O "$BASE/loras/flux-2-klein-9b_odi_V1.safetensors" "https://www.dropbox.com/scl/fi/qkdbb5nsjammi4gp0hfo1/flux-2-klein-9b_odi_V1.safetensors?rlkey=ixajje8wpyuzw1s4kxvjurslc&st=vm58nmrr&dl=1"

#https://www.dropbox.com/scl/fi/276wfijwnrlqutslfqtwx/flux2_klein_skin_4.safetensors?rlkey=w3t0qgbl3a3529idhxf9g5rhp&st=8ijajtre&dl=0
download_model "flux2_klein_skin_4.safetensors" wget -O "$BASE/loras/flux2_klein_skin_4.safetensors" "https://www.dropbox.com/scl/fi/276wfijwnrlqutslfqtwx/flux2_klein_skin_4.safetensors?rlkey=w3t0qgbl3a3529idhxf9g5rhp&st=8ijajtre&dl=1"

#https://www.dropbox.com/scl/fi/nkedj1v2fgkmh4hkjuwbh/Flux3_skin_texture-step-5000.safetensors?rlkey=8trmfrkpmi76wekaw7n4xxjhp&st=ccksiwsk&dl=0
download_model "Flux3_skin_texture-step-5000.safetensors" wget -O "$BASE/loras/Flux3_skin_texture-step-5000.safetensors" "https://www.dropbox.com/scl/fi/nkedj1v2fgkmh4hkjuwbh/Flux3_skin_texture-step-5000.safetensors?rlkey=8trmfrkpmi76wekaw7n4xxjhp&st=ccksiwsk&dl=1"

#https://www.dropbox.com/scl/fi/2nesydurq0udcnhkxl1fa/Klein9b_ultra_real_v5_pro.safetensors?rlkey=n8xdd6b5oy1u5t901eo9xmhcz&st=w5ffllmh&dl=0
download_model "Klein9b_ultra_real_v5_pro.safetensors" wget -O "$BASE/loras/Klein9b_ultra_real_v5_pro.safetensors" "https://www.dropbox.com/scl/fi/2nesydurq0udcnhkxl1fa/Klein9b_ultra_real_v5_pro.safetensors?rlkey=n8xdd6b5oy1u5t901eo9xmhcz&st=w5ffllmh&dl=1"

#https://www.dropbox.com/scl/fi/9jsopj6oxqtva4mbuvi1w/Flux3_klein_facial_texture_10000.safetensors?rlkey=xdevnl7xbflkfrztlgvr3e1q9&st=z3hrkyp3&dl=0
download_model "Flux3_klein_facial_texture_10000.safetensors" wget -O "$BASE/loras/Flux3_klein_facial_texture_10000.safetensors" "https://www.dropbox.com/scl/fi/9jsopj6oxqtva4mbuvi1w/Flux3_klein_facial_texture_10000.safetensors?rlkey=xdevnl7xbflkfrztlgvr3e1q9&st=z3hrkyp3&dl=1"

#https://huggingface.co/datasets/hardlyworking/Vagina-Vision-Image-Folder-Captions-Included/tree/main
# =========================================================
# DETECT FLUX VERSION
# =========================================================

# Default: FLUX.2
USE_FLUX3=0

# Check environment capability
if [ "${FLUX3:-0}" = "1" ] || [ "${USE_FLUX3:-0}" = "1" ]; then
    USE_FLUX3=1
fi

if [ "$USE_FLUX3" = "1" ]; then
    echo "[INFO] FLUX.3 environment detected"
else
    echo "[INFO] FLUX.3 not detected - using FLUX.2"
fi


# =========================================================
# DOWNLOAD FLUX.3 KLEIN
# =========================================================

if [ "$USE_FLUX3" = "1" ]; then

    REPO="black-forest-labs/flux-3-image-klein-comfy"

    # -----------------------------------------------------
    # 1. DIFFUSION MODEL
    # -----------------------------------------------------

    echo "Downloading FLUX.3 diffusion model"

    download_model "FLUX.3 Klein Diffusion INT8" \
      hf download "$REPO" \
      diffusion_models/flux3-image-klein-int8-convrot.safetensors \
      --local-dir "$BASE"

    # -----------------------------------------------------
    # 2. PROMPT UPSAMPLER
    # -----------------------------------------------------

    echo "Downloading FLUX.3 Prompt Upsampler"

    download_model "FLUX.3 Qwen3.5 9B Prompt Upsampler W4A8" \
      hf download "$REPO" \
      text_encoders/qwen3.5_9b_flux3_prompt_upsampler_w4a8.safetensors \
      --local-dir "$BASE"

    # -----------------------------------------------------
    # 3. CLIP
    # -----------------------------------------------------

    echo "Downloading FLUX.3 Qwen3-VL"

    download_model "FLUX.3 Qwen3-VL 4B INT8" \
      hf download "$REPO" \
      text_encoders/qwen3vl_4b_int8_convrot.safetensors \
      --local-dir "$BASE"

    # -----------------------------------------------------
    # 4. VAE
    # -----------------------------------------------------

    echo "Downloading FLUX.3 VAE"

    download_model "FLUX.3 Klein VAE" \
      hf download "$REPO" \
      vae/flux2-vae.safetensors \
      --local-dir "$BASE"

    echo "[INFO] FLUX.3 download completed"


# =========================================================
# DOWNLOAD FLUX.2 KLEIN (DEFAULT)
# =========================================================

else

    # -----------------------------------------------------
    # 1. DIFFUSION MODEL
    # -----------------------------------------------------

    echo "Downloading flux-2-klein-9b-fp8.safetensors"

    if [ "${COLAB:-}" = "1" ]; then
        echo "[INFO] Downloading using gdown for Colab"

        download_model "FLUX.2 Klein 9B FP8" \
          gdown --continue \
          "1vOVw0uXxjhpwy1Q2QyHmRsvegLMc5VTG" \
          -O "/app/ComfyUI/models/diffusion_models/flux-2-klein-9b-fp8.safetensors"
    else
        download_model "FLUX.2 Klein 9B FP8" \
          hf download black-forest-labs/FLUX.2-klein-9b-fp8 \
          flux-2-klein-9b-fp8.safetensors \
          --local-dir "$BASE/diffusion_models"
    fi

    # -----------------------------------------------------
    # 2. CLIP
    # -----------------------------------------------------

    echo "Downloading qwen_3_8b_fp8mixed.safetensors"

    download_model "FLUX.2 Qwen3 8B" \
      hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b \
      split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors \
      --local-dir "$BASE/clip"

    if [ -f "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" ]; then
        mv "$BASE/clip/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
           "$BASE/clip/qwen_3_8b_fp8mixed.safetensors"
    fi

    # -----------------------------------------------------
    # 3. VAE
    # -----------------------------------------------------

    echo "Downloading flux2-vae.safetensors"

    download_model "FLUX.2 Klein VAE" \
      hf download Comfy-Org/vae-text-encorder-for-flux-klein-9b \
      split_files/vae/flux2-vae.safetensors \
      --local-dir "$BASE/vae"

    if [ -f "$BASE/vae/split_files/vae/flux2-vae.safetensors" ]; then
        mv "$BASE/vae/split_files/vae/flux2-vae.safetensors" \
           "$BASE/vae/flux2-vae.safetensors"
    fi

    echo "[INFO] FLUX.2 download completed"

fi

echo "✅ Download complete!"
