#!/bin/bash
set -euo pipefail

MODEL="/app/ComfyUI/models/diffusion_models/flux-2-klein-9b-fp8.safetensors"

if [ ! -s "$MODEL" ]; then
    echo "[INFO] Model not found, downloading in background..."

    if [ "${HF_AUTO_DOWNLOAD:-1}" != "0" ] && [ -f /app/hubfacedownload.sh ]; then
        chmod +x /app/hubfacedownload.sh
        nohup /app/hubfacedownload.sh \
            > /app/hubfacedownload.log 2>&1 &
        echo "[INFO] Download PID: $!"
    fi
else
    echo "[INFO] Model found: $(du -h "$MODEL" | cut -f1)"
fi

echo "[INFO] Starting ComfyUI..."
cd /app/ComfyUI

exec python3 main.py \
    --listen 0.0.0.0 \
    --port 8188