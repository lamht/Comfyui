#!/usr/bin/env bash
set -e

echo "======================================"
echo " NVIDIA GPU / PyTorch Auto Installer"
echo "======================================"

python3 -m pip install --upgrade pip setuptools wheel
pip uninstall -y torch torchvision torchaudio || true

# Detect GPU compute capability
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)

if [ -z "$GPU_NAME" ]; then
    echo "ERROR: NVIDIA GPU not detected."
    exit 1
fi

echo "GPU: $GPU_NAME"

# Get compute capability using nvidia-smi where possible
CC=$(python3 - <<'PY'
try:
    import torch
    if torch.cuda.is_available():
        cc = torch.cuda.get_device_capability(0)
        print(f"{cc[0]}.{cc[1]}")
    else:
        print("")
except Exception:
    print("")
PY
)

# If torch isn't installed yet, identify common GPU families by name.
# V100 / Tesla V100 = SM70
if echo "$GPU_NAME" | grep -Eqi 'V100|Titan V'; then
    CC="7.0"
fi

if [ -z "$CC" ]; then
    case "$GPU_NAME" in
        *T4*|*"RTX 20"*|*"Quadro RTX"*)
            CC="7.5"
            ;;
        *A100*|*A30*|*"RTX 30"*|*"RTX A"*)
            CC="8.0"
            ;;
        *A40*|*A6000*|*"RTX 3090"*|*"RTX 3080"*|*"RTX 3070"*|*"RTX 3060"*)
            CC="8.6"
            ;;
        *H100*|*H200*)
            CC="9.0"
            ;;
        *L40*|*L40S*|*"RTX 40"*|*"RTX 4090"*|*"RTX 4080"*|*"RTX 4070"*)
            CC="8.9"
            ;;
        *"RTX 50"*|*"RTX PRO 50"*|*B100*|*B200*|*GB200*)
            CC="10.0"
            ;;
        *)
            echo "WARNING: Unknown GPU architecture."
            echo "GPU: $GPU_NAME"
            echo "Install legacy-safe PyTorch CUDA 12.6."
            CC="7.0"
            ;;
    esac
fi

echo "Compute Capability: $CC"

# ============================================================
# Volta / old GPUs: SM 5.x / 6.x / 7.0
# Use PyTorch 2.14 + CUDA 12.6
# ============================================================

case "$CC" in
    5.*|6.*|7.0)
        echo
        echo ">>> Legacy / Volta GPU detected"
        echo ">>> Installing PyTorch 2.14 + CUDA 12.6"

        python3 -m pip uninstall -y \
            torch torchvision torchaudio \
            xformers 2>/dev/null || true

        python3 -m pip install \
            torch==2.14.0 \
            torchvision==0.24.0 \
            torchaudio==2.14.0 \
            --index-url https://download.pytorch.org/whl/cu126
        ;;

    # Turing / Ampere / Hopper / Blackwell
    *)
        echo
        echo ">>> Modern GPU detected"
        echo ">>> Installing latest PyTorch CUDA build"

        python3 -m pip uninstall -y \
            torch torchvision torchaudio \
            xformers 2>/dev/null || true

        python3 -m pip install \
            torch torchvision torchaudio
        ;;
esac

echo
echo "======================================"
echo " PyTorch CUDA TEST"
echo "======================================"

python3 - <<'PY'
import torch

print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    raise SystemExit("ERROR: CUDA is NOT available")

for i in range(torch.cuda.device_count()):
    print(f"GPU {i}:", torch.cuda.get_device_name(i))
    print(f"CC {i}:", torch.cuda.get_device_capability(i))

x = torch.randn(1, 3, 64, 64, device="cuda")
conv = torch.nn.Conv2d(3, 16, 3).cuda()
y = conv(x)

print("CUDA test OK:", y.shape)
PY

echo
echo "======================================"
echo " INSTALL PYTORCH COMPLETE"
echo "======================================"