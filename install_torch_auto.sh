#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo " NVIDIA GPU / PyTorch Auto Installer"
echo "======================================"

# ============================================================
# ComfyUI Python
# ============================================================

COMFY_DIR="/app/ComfyUI"
PYTHON="${COMFY_DIR}/venv/bin/python"

if [ ! -x "$PYTHON" ]; then
    echo "ERROR: ComfyUI Python not found:"
    echo "  $PYTHON"
    exit 1
fi

echo "Python: $PYTHON"
"$PYTHON" --version

# Always use pip belonging to the ComfyUI venv
"$PYTHON" -m pip install --upgrade pip setuptools wheel

# ============================================================
# Detect NVIDIA GPU
# ============================================================

GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)

if [ -z "$GPU_NAME" ]; then
    echo
    echo "ERROR: NVIDIA GPU not detected."
    exit 1
fi

echo
echo "GPU: $GPU_NAME"

# ============================================================
# Detect Compute Capability
#
# We cannot use torch here because torch may have been removed.
# Therefore detect common NVIDIA GPU families by name.
# ============================================================

CC=""

case "$GPU_NAME" in

    # --------------------------------------------------------
    # Volta
    # --------------------------------------------------------
    *V100*|*"Tesla V100"*|*"Titan V"*)
        CC="7.0"
        ;;

    # --------------------------------------------------------
    # Turing
    # --------------------------------------------------------
    *T4*|*"Tesla T4"*|*"RTX 20"*|*"Quadro RTX"*|*"RTX 5000"*)
        CC="7.5"
        ;;

    # --------------------------------------------------------
    # Ampere
    # --------------------------------------------------------
    *A100*|*"A30"*|*"RTX 30"*|*"RTX 3090"*|*"RTX 3080"*|*"RTX 3070"*|*"RTX 3060"*)
        CC="8.0"
        ;;

    *A40*|*"A6000"*|*"RTX A"*|*"RTX 4000 Ada"*|*"RTX 5000 Ada"*|*"RTX 6000 Ada"*)
        CC="8.6"
        ;;

    # --------------------------------------------------------
    # Ada Lovelace
    # --------------------------------------------------------
    *L40*|*L40S*|*"RTX 40"*|*"RTX 4090"*|*"RTX 4080"*|*"RTX 4070"*|*"RTX 4060"*|*"RTX 4050"*)
        CC="8.9"
        ;;

    # --------------------------------------------------------
    # Hopper
    # --------------------------------------------------------
    *H100*|*H200*)
        CC="9.0"
        ;;

    # --------------------------------------------------------
    # Blackwell
    # --------------------------------------------------------
    *"RTX 50"*|*"RTX PRO 50"*|*B100*|*B200*|*GB200*)
        CC="10.0"
        ;;

    *)
        echo
        echo "WARNING: Unknown NVIDIA GPU architecture."
        echo "GPU: $GPU_NAME"
        echo
        echo "Cannot safely select a PyTorch CUDA build."
        echo "Please check the GPU manually."
        exit 1
        ;;
esac

echo "Compute Capability: $CC"

# ============================================================
# Remove existing PyTorch
# ============================================================

echo
echo "======================================"
echo " Removing existing PyTorch packages"
echo "======================================"

"$PYTHON" -m pip uninstall -y \
    torch \
    torchvision \
    torchaudio \
    xformers \
    2>/dev/null || true

# ============================================================
# Install PyTorch
# ============================================================

case "$CC" in

    # ========================================================
    # SM 7.0
    #
    # Tesla V100 / Titan V
    #
    # IMPORTANT:
    # torch 2.14 + cu130 does NOT contain SM70 kernels.
    # Use CUDA 12.6 build.
    #
    # cu126 index does NOT provide torchaudio 2.14.
    # ComfyUI does not require torchaudio for normal operation.
    # ========================================================

    7.0)

        echo
        echo "======================================"
        echo " Legacy / Volta GPU"
        echo " Tesla V100 / SM 7.0"
        echo "======================================"

        echo "Installing:"
        echo "  torch       2.14.0 + cu126"
        echo "  torchvision 0.24.0 + cu126"
        echo "  torchaudio  SKIPPED"

        "$PYTHON" -m pip install \
            torch==2.14.0 \
            torchvision==0.24.0 \
            --index-url https://download.pytorch.org/whl/cu126
        ;;

    # ========================================================
    # Other supported GPUs
    # ========================================================

    *)

        echo
        echo "======================================"
        echo " Modern NVIDIA GPU"
        echo "======================================"

        echo "Installing PyTorch from default PyPI..."

        "$PYTHON" -m pip install \
            torch \
            torchvision \
            torchaudio

        ;;

esac

# ============================================================
# Verify installation
# ============================================================

echo
echo "======================================"
echo " PyTorch CUDA TEST"
echo "======================================"

"$PYTHON" - <<'PY'
import sys

print("Python:", sys.executable)

try:
    import torch
except Exception as e:
    print("ERROR: Cannot import torch")
    print(e)
    raise SystemExit(1)

print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    print()
    print("ERROR: CUDA is NOT available")
    raise SystemExit(1)

print("CUDA device count:", torch.cuda.device_count())

for i in range(torch.cuda.device_count()):
    name = torch.cuda.get_device_name(i)
    cc = torch.cuda.get_device_capability(i)

    print(f"GPU {i}: {name}")
    print(f"CC {i}: {cc[0]}.{cc[1]}")

# ------------------------------------------------------------
# Real CUDA kernel test
# ------------------------------------------------------------

print()
print("Running CUDA kernel test...")

device = torch.device("cuda")

x = torch.randn(
    1,
    3,
    64,
    64,
    device=device
)

conv = torch.nn.Conv2d(
    3,
    16,
    3
).to(device)

y = conv(x)

# Force CUDA synchronization so kernel errors are actually caught
torch.cuda.synchronize()

print("Input :", x.shape)
print("Output:", y.shape)
print()
print("CUDA TEST OK")

PY

# ============================================================
# Final information
# ============================================================

echo
echo "======================================"
echo " INSTALL PYTORCH COMPLETE"
echo "======================================"

"$PYTHON" -m pip show torch | grep -E '^(Name|Version):' || true
"$PYTHON" -m pip show torchvision | grep -E '^(Name|Version):' || true

echo
echo "ComfyUI Python:"
echo "  $PYTHON"

echo
echo "Start ComfyUI with:"
echo "  cd $COMFY_DIR"
echo "  ./venv/bin/python main.py --listen 0.0.0.0 --port 8188"

echo
echo "======================================"
