#!/usr/bin/env bash

# ==============================
# SCRIPT PATHS
# ==============================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export COMFY_PATH="$SCRIPT_DIR/ComfyUI"

ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"

# ==============================
# CHECK PYTHON & CREATE VENV
# ==============================

if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is not installed."
    exit 1
fi

if [ ! -d "$COMFY_PATH/venv" ]; then
    echo "[+] Creating virtual environment..."

    python3 -m venv "$COMFY_PATH/venv" || {
        echo "ERROR: Failed to create virtual environment."
        exit 1
    }
fi

PYTHON="$COMFY_PATH/venv/bin/python"

echo "[+] Python: $PYTHON"
"$PYTHON" --version

# ==============================
# ENVIRONMENT
# ==============================

export PYTHONUNBUFFERED=1
export PYTHONPATH="$COMFY_PATH"
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

echo "[+] COMFY_PATH=$COMFY_PATH"
echo "[+] CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"

# ==============================
# CHECK PYTORCH
# ==============================

"$PYTHON" - <<'PY'
import torch

print("[+] Torch:", torch.__version__)
print("[+] CUDA runtime:", torch.version.cuda)
print("[+] CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("[+] GPU:", torch.cuda.get_device_name(0))
    print("[+] Compute Capability:", torch.cuda.get_device_capability(0))
PY

# ==============================
# STOP EXISTING COMFYUI
# ==============================

echo "[+] Stopping existing ComfyUI..."

pkill -f "$COMFY_PATH/main.py" 2>/dev/null || true

sleep 2

# ==============================
# START COMFYUI
# ==============================

echo "[+] Starting ComfyUI..."

nohup "$PYTHON" \
    "$COMFY_PATH/main.py" \
    --listen 0.0.0.0 \
    --port 8189 \
    > "$SCRIPT_DIR/comfy.log" 2>&1 &

COMFY_PID=$!

echo "[+] ComfyUI PID: $COMFY_PID"
echo "[+] Log: $SCRIPT_DIR/comfy.log"

sleep 3

# ==============================
# CHECK PROCESS
# ==============================

if kill -0 "$COMFY_PID" 2>/dev/null; then
    echo "[+] ComfyUI process is running."
else
    echo "[!] ComfyUI failed to start."
    echo
    echo "===== LAST LOG ====="
    tail -100 "$SCRIPT_DIR/comfy.log"
    exit 1
fi

echo
echo "======================================"
echo " ComfyUI STARTED"
echo "======================================"
echo " URL : http://0.0.0.0:8189"
echo " PID : $COMFY_PID"
echo " LOG : $SCRIPT_DIR/comfy.log"
echo "======================================"