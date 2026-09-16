#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo " NVIDIA GPU / PyTorch Auto Installer"
echo "======================================"

# ============================================================
# ComfyUI environment
# ============================================================

COMFY_DIR="/app/ComfyUI"
PYTHON="${COMFY_DIR}/venv/bin/python"

if [ ! -x "$PYTHON" ]; then
    echo "ERROR: ComfyUI venv not found:"
    echo "  $PYTHON"
    exit 1
fi

echo "Python: $PYTHON"
"$PYTHON" --version

# ============================================================
# GPU detection
# ============================================================

GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)

if [ -z "$GPU_NAME" ]; then
    echo "ERROR: NVIDIA GPU not detected."
    exit 1
fi

echo "GPU: $GPU_NAME"

# ============================================================
# Detect Compute Capability
# ============================================================

CC=""

case "$GPU_NAME" in

    # Volta
    *V100*|*"Tesla V100"*|*"Titan V"*)
        CC="7.0"
        ;;

    # Turing
    *T4*|*"Tesla T4"*|*"RTX 20"*|*"Quadro RTX"*)
        CC="7.5"
        ;;

    # Ampere
    *A100*|*A30*|*"RTX 30"*|*"RTX 3090"*|*"RTX 3080"*|*"RTX 3070"*|*"RTX 3060"*)
        CC="8.0"
        ;;

    *A40*|*A6000*|*"RTX A"*)
        CC="8.6"
        ;;

    # Ada
    *L40*|*L40S*|*"RTX 40"*|*"RTX 4090"*|*"RTX 4080"*|*"RTX 4070"*|*"RTX 4060"*)
        CC="8.9"
        ;;

    # Hopper
    *H100*|*H200*)
        CC="9.0"
        ;;

    # Blackwell
    *"RTX 50"*|*"RTX PRO 50"*|*B100*|*B200*|*GB200*)
        CC="10.0"
        ;;

    *)
        echo
        echo "ERROR: Unknown NVIDIA GPU architecture."
        echo "GPU: $GPU_NAME"
        exit 1
        ;;
esac

echo "Compute Capability: $CC"

# ============================================================
# Upgrade pip
# ============================================================

"$PYTHON" -m pip install --upgrade pip setuptools wheel

# ============================================================
# Remove old PyTorch
# ============================================================

echo
echo "======================================"
echo " Removing old PyTorch packages"
echo "======================================"

"$PYTHON" -m pip uninstall -y \
    torch \
    torchvision \
    torchaudio \
    xformers \
    2>/dev/null || true

# ============================================================
# V100 / Volta
#
# cu126 currently provides:
#
# torch       2.9.0+cu126
# torchvision 0.24.0+cu126
# torchaudio  2.9.0+cu126
#
# DO NOT use torch 2.14 + torchvision 0.24.
# ============================================================

if [ "$CC" = "7.0" ]; then

    echo
    echo "======================================"
    echo " Tesla V100 / Volta SM 7.0"
    echo "======================================"

    echo
    echo "Installing:"
    echo "  torch       2.9.0 + cu126"
    echo "  torchvision 0.24.0 + cu126"
    echo "  torchaudio  2.9.0 + cu126"
    echo

    "$PYTHON" -m pip install \
        torch==2.9.0 \
        torchvision==0.24.0 \
        torchaudio==2.9.0 \
        --index-url https://download.pytorch.org/whl/cu126

else

    echo
    echo "======================================"
    echo " Modern NVIDIA GPU"
    echo "======================================"

    "$PYTHON" -m pip install \
        torch \
        torchvision \
        torchaudio

fi

# ============================================================
# Verify versions
# ============================================================

echo
echo "======================================"
echo " Installed Versions"
echo "======================================"

"$PYTHON" - <<'PY'
import torch

print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)

try:
    import torchvision
    print("Torchvision:", torchvision.__version__)
except Exception as e:
    print("Torchvision ERROR:", e)

try:
    import torchaudio
    print("Torchaudio:", torchaudio.__version__)
except Exception as e:
    print("Torchaudio:", e)
PY

# ============================================================
# CUDA test
# ============================================================

echo
echo "======================================"
echo " CUDA KERNEL TEST"
echo "======================================"

"$PYTHON" - <<'PY'
import torch

print("Python:", torch.__version__)
print("CUDA runtime:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is NOT available")

for i in range(torch.cuda.device_count()):
    name = torch.cuda.get_device_name(i)
    cc = torch.cuda.get_device_capability(i)

    print(f"GPU {i}: {name}")
    print(f"CC {i}: {cc[0]}.{cc[1]}")

print()
print("Running CUDA kernel...")

x = torch.randn(
    1, 3, 64, 64,
    device="cuda"
)

conv = torch.nn.Conv2d(
    3, 16, 3
).cuda()

y = conv(x)

torch.cuda.synchronize()

print("Input :", x.shape)
print("Output:", y.shape)
print()
print("======================================")
print(" CUDA TEST OK")
print("======================================")
PY

echo
echo "======================================"
echo " INSTALL COMPLETE"
echo "======================================"

echo
echo "Start ComfyUI:"
echo "cd $COMFY_DIR"
echo "./venv/bin/python main.py --listen 0.0.0.0 --port 8188"
