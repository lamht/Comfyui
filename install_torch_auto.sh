#!/usr/bin/env bash
set -euo pipefail

echo
echo "=============================================="
echo " NVIDIA GPU / PyTorch AUTO INSTALLER"
echo "=============================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMFY_DIR="${COMFY_PATH:-$SCRIPT_DIR/ComfyUI}"
PYTHON="${COMFY_DIR}/venv/bin/python"

if [ ! -x "$PYTHON" ]; then
    echo
    echo "ERROR: ComfyUI venv not found:"
    echo "  $PYTHON"
    exit 1
fi

echo
echo "Python:"
"$PYTHON" --version

# --------------------------------------------------
# GPU detection
# --------------------------------------------------

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "ERROR: nvidia-smi not found."
    exit 1
fi

GPU_NAME="$(
    nvidia-smi \
        --query-gpu=name \
        --format=csv,noheader \
        2>/dev/null | head -1
)"

if [ -z "$GPU_NAME" ]; then
    echo "ERROR: NVIDIA GPU not detected."
    exit 1
fi

echo
echo "GPU:"
echo "  $GPU_NAME"

# --------------------------------------------------
# Architecture detection
# --------------------------------------------------

ARCH="Unknown"
CC="unknown"

case "$GPU_NAME" in
    *"V100"*|*"Titan V"*)
        ARCH="Volta"
        CC="7.0"
        ;;
    *"T4"*|*"RTX 20"*|*"Quadro RTX"*)
        ARCH="Turing"
        CC="7.5"
        ;;
    *"A100"*|*"A30"*)
        ARCH="Ampere"
        CC="8.0"
        ;;
    *"A40"*|*"A6000"*|*"RTX 30"*)
        ARCH="Ampere"
        CC="8.6"
        ;;
    *"L40"*|*"RTX 40"*)
        ARCH="Ada"
        CC="8.9"
        ;;
    *"H100"*|*"H200"*)
        ARCH="Hopper"
        CC="9.0"
        ;;
    *"B100"*|*"B200"*|*"GB200"*|*"RTX 50"*)
        ARCH="Blackwell"
        CC="10.0"
        ;;
esac

echo
echo "Architecture: $ARCH"
echo "Compute Capability: $CC"

# --------------------------------------------------
# Select target PyTorch runtime
# --------------------------------------------------

if [ "$ARCH" = "Volta" ]; then
    # PyTorch 2.4.1 support for Python 3.12, CUDA 12.1, and torch.library.custom_op
    EXPECTED_TORCH_VERSION="2.4.1"
    EXPECTED_TORCHVISION_VERSION="0.19.1"
    EXPECTED_TORCHAUDIO_VERSION="2.4.1"
    EXPECTED_TORCH_CUDA="12.1"
    
    TORCH_PKG="torch==2.4.1+cu121"
    TORCHVISION_PKG="torchvision==0.19.1+cu121"
    TORCHAUDIO_PKG="torchaudio==2.4.1+cu121"
    INDEX_URL="https://download.pytorch.org/whl/cu121"

elif [ "$ARCH" != "Unknown" ]; then
    EXPECTED_TORCH_VERSION="2.5.1"
    EXPECTED_TORCHVISION_VERSION="0.20.1"
    EXPECTED_TORCHAUDIO_VERSION="2.5.1"
    EXPECTED_TORCH_CUDA="12.4"
    
    TORCH_PKG="torch==2.5.1+cu124"
    TORCHVISION_PKG="torchvision==0.20.1+cu124"
    TORCHAUDIO_PKG="torchaudio==2.5.1+cu124"
    INDEX_URL="https://download.pytorch.org/whl/cu124"

else
    echo
    echo "ERROR: Unsupported / unknown NVIDIA GPU: $GPU_NAME"
    exit 1
fi

# --------------------------------------------------
# Reuse a healthy existing PyTorch stack
# --------------------------------------------------

echo
echo "=============================================="
echo " Checking existing PyTorch packages"
echo "=============================================="

if EXPECTED_TORCH_VERSION="$EXPECTED_TORCH_VERSION" \
   EXPECTED_TORCHVISION_VERSION="$EXPECTED_TORCHVISION_VERSION" \
   EXPECTED_TORCH_CUDA="$EXPECTED_TORCH_CUDA" \
   EXPECTED_TORCHAUDIO_VERSION="$EXPECTED_TORCHAUDIO_VERSION" \
   "$PYTHON" - <<'PY'
import os
import numpy as np
import torch
import torchvision
import torchaudio

expected_torch = os.environ.get("EXPECTED_TORCH_VERSION", "")
expected_torchvision = os.environ.get("EXPECTED_TORCHVISION_VERSION", "")
expected_cuda = os.environ.get("EXPECTED_TORCH_CUDA", "")
expected_torchaudio = os.environ.get("EXPECTED_TORCHAUDIO_VERSION", "")

# Verify NumPy version constraint (<2.0.0)
numpy_major = int(np.__version__.split(".")[0])
if numpy_major >= 2:
    raise RuntimeError(f"NumPy version must be < 2.0.0, found {np.__version__}")

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

if expected_torch and torch.__version__.split("+")[0] != expected_torch:
    raise RuntimeError(f"expected torch {expected_torch}, found {torch.__version__}")
if expected_torchvision and torchvision.__version__.split("+")[0] != expected_torchvision:
    raise RuntimeError(f"expected torchvision {expected_torchvision}, found {torchvision.__version__}")
if expected_cuda and torch.version.cuda != expected_cuda:
    raise RuntimeError(f"expected CUDA {expected_cuda}, found {torch.version.cuda}")
if expected_torchaudio and torchaudio.__version__.split("+")[0] != expected_torchaudio:
    raise RuntimeError(f"expected torchaudio {expected_torchaudio}, found {torchaudio.__version__}")

# Verify critical API attribute for comfy_kitchen
if not hasattr(torch.library, "custom_op"):
    raise RuntimeError("torch.library does not have custom_op attribute")

torch.zeros(1, device="cuda")
torch.cuda.synchronize()

print(f"torch       : {torch.__version__}")
print(f"torchvision : {torchvision.__version__}")
print(f"torchaudio  : {torchaudio.__version__}")
print(f"numpy       : {np.__version__}")
print(f"CUDA        : {torch.version.cuda}")
print(f"GPU         : {torch.cuda.get_device_name(0)}")
PY
then
    echo
    echo "[INFO] Existing PyTorch stack is healthy; skipping reinstall."
    exit 0
else
    echo
    echo "[INFO] Existing PyTorch stack is missing or unhealthy. Proceeding to fix..."
fi

# --------------------------------------------------
# Remove existing broken PyTorch stack & incompatible dependencies
# --------------------------------------------------

echo
echo "=============================================="
echo " Cleaning old PyTorch & NumPy packages"
echo "=============================================="

"$PYTHON" -m pip uninstall -y \
    torch \
    torchvision \
    torchaudio \
    xformers \
    triton \
    pynvml 2>/dev/null || true

# --------------------------------------------------
# Install target PyTorch Stack & Lock NumPy < 2
# --------------------------------------------------

echo
echo "=============================================="
echo " Installing fresh PyTorch stack for $ARCH"
echo "=============================================="

"$PYTHON" -m pip install --upgrade pip setuptools wheel
"$PYTHON" -m pip install "numpy<2" nvidia-ml-py

"$PYTHON" -m pip install \
    "$TORCH_PKG" \
    "$TORCHVISION_PKG" \
    "$TORCHAUDIO_PKG" \
    --index-url "$INDEX_URL"

# --------------------------------------------------
# Final verification
# --------------------------------------------------

echo
echo "=============================================="
echo " CUDA verification test"
echo "=============================================="

"$PYTHON" - <<'PY'
import sys
import torch

if not torch.cuda.is_available():
    print("ERROR: CUDA is NOT available after installation.")
    sys.exit(1)

a = torch.randn((1024, 1024), device="cuda")
b = torch.randn((1024, 1024), device="cuda")
c = a @ b
torch.cuda.synchronize()

print(f"SUCCESS: PyTorch {torch.__version__} (CUDA {torch.version.cuda}) working on {torch.cuda.get_device_name(0)}")
PY

echo
echo "=============================================="
echo " INSTALLATION COMPLETE"
echo "=============================================="