#!/bin/bash
set -euo pipefail

# If HF_AUTO_DOWNLOAD is enabled (default 1), run the hubface download script
if [ "${HF_AUTO_DOWNLOAD:-1}" != "0" ]; then
  if [ -f /app/hubfacedownload.sh ]; then
    echo "Running hubfacedownload.sh to fetch models (if HF_TOKEN provided)"
    chmod +x /app/hubfacedownload.sh
    # Allow the script to fail without killing the container
    nohup /app/hubfacedownload.sh || echo "hubfacedownload.sh failed or skipped"
  else
    echo "No hubfacedownload.sh found; skipping model download"
  fi
fi

# Start ComfyUI
cd /app/ComfyUI
exec python main.py --listen 0.0.0.0 --port 8188


