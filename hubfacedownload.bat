:: ==============================
:: SET TOKEN
:: ==============================
:: set HF_TOKEN=hf_your_new_token_here

:: ==============================
:: Download hubface cli
:: ==============================
powershell -ExecutionPolicy ByPass -c "irm https://hf.co/cli/install.ps1 | iex"

set HF_HUB_ENABLE_HF_TRANSFER=1
:: ==============================
:: LOGIN
:: ==============================
huggingface-cli login --token %HF_TOKEN%

:: ==============================
:: BASE PATH
:: ==============================
set BASE=ComfyUI\models

:: ==============================
:: DOWNLOAD LORA
:: ==============================
huggingface-cli download BuckyDroid/test_lora ^
  --include scg-anatomy-female-v2.safetensors ^
  --local-dir %BASE%\loras

:: ==============================
:: DOWNLOAD LORA (FACE SWAP)
:: ==============================
huggingface-cli download Alissonerdx/BFS-Best-Face-Swap ^
  --include bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors ^
  --local-dir %BASE%\loras

:: ==============================
:: DOWNLOAD CHECKPOINT
:: ==============================
huggingface-cli download black-forest-labs/FLUX.2-klein-9B ^
  --include flux-2-klein-9b.safetensors ^
  --local-dir %BASE%\checkpoints

:: ==============================
:: DOWNLOAD CLIP
:: ==============================
huggingface-cli download Comfy-Org/vae-text-encorder-for-flux-klein-9b ^
  --include split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors ^
  --local-dir %BASE%\clip

:: ==============================
:: DOWNLOAD VAE
:: ==============================
huggingface-cli download Comfy-Org/vae-text-encorder-for-flux-klein-9b ^
  --include split_files/vae/flux2-vae.safetensors ^
  --local-dir %BASE%\vae

echo Download complete!