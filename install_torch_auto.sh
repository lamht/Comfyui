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

ARCH=""
CC=""

case "$GPU_NAME" in

    # ----------------------------------------------
    # VOLTA
    # ----------------------------------------------
    *"Tesla V100"*|*"V100"*|*"Titan V"*)
        ARCH="Volta"
        CC="7.0"
        ;;

    # ----------------------------------------------
    # TURING
    # ----------------------------------------------
    *"Tesla T4"*|*"T4"*|\
    *"RTX 20"*|\
    *"Quadro RTX 20"*|\
    *"Quadro RTX 4000"*|\
    *"Quadro RTX 5000"*|\
    *"Quadro RTX 6000"*|\
    *"Quadro RTX 8000"*)
        ARCH="Turing"
        CC="7.5"
        ;;

    # ----------------------------------------------
    # AMPERE SM 8.0
    # ----------------------------------------------
    *"A100"*|*"A30"*)
        ARCH="Ampere"
        CC="8.0"
        ;;

    # ----------------------------------------------
    # AMPERE SM 8.6
    # ----------------------------------------------
    *"A40"*|*"A6000"*|\
    *"RTX 30"*|\
    *"RTX 3090"*|*"RTX 3080"*|\
    *"RTX 3070"*|*"RTX 3060"*|\
    *"RTX 3050"*)
        ARCH="Ampere"
        CC="8.6"
        ;;

    # ----------------------------------------------
    # ADA
    # ----------------------------------------------
    *"L40"*|*"L40S"*|\
    *"RTX 40"*|\
    *"RTX 4090"*|*"RTX 4080"*|\
    *"RTX 4070"*|*"RTX 4060"*|\
    *"RTX 4050"*)
        ARCH="Ada"
        CC="8.9"
        ;;

    # ----------------------------------------------
    # HOPPER
    # ----------------------------------------------
    *"H100"*|*"H200"*)
        ARCH="Hopper"
        CC="9.0"
        ;;

    # ----------------------------------------------
    # BLACKWELL
    # ----------------------------------------------
    *"B100"*|*"B200"*|*"GB200"*|\
    *"RTX 50"*|*"RTX PRO 50"*)
        ARCH="Blackwell"
        CC="10.x"
        ;;

    *)
        ARCH="Unknown"
        CC="unknown"
        ;;
esac

echo
echo "Architecture:"
echo "  $ARCH"

echo "Compute Capability:"
echo "  $CC"

# --------------------------------------------------
# Reuse a healthy existing PyTorch stack
# --------------------------------------------------

echo
echo "=============================================="
echo " Checking existing PyTorch packages"
echo "=============================================="

if EXISTING_STACK_INFO="$("$PYTHON" - <<'PY'
import importlib.util
import torch
import torchvision
import torchaudio

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

torch.zeros(1, device="cuda")
torch.cuda.synchronize()

boxes = torch.tensor(
    [[0, 0, 10, 10], [1, 1, 9, 9]],
    dtype=torch.float32,
    device="cuda",
)
scores = torch.tensor([0.9, 0.8], dtype=torch.float32, device="cuda")
keep = torchvision.ops.nms(boxes, scores, 0.5)
torch.cuda.synchronize()
if keep.numel() != 1:
    raise RuntimeError(f"torchvision NMS returned {keep.numel()} boxes")

waveform = torch.randn(1, 160, dtype=torch.float32)
resampled = torchaudio.functional.resample(waveform, 16000, 8000)
if resampled.shape[-1] != 80:
    raise RuntimeError(f"torchaudio resample returned shape {tuple(resampled.shape)}")

print(f"torch       : {torch.__version__}")
print(f"torchvision : {torchvision.__version__}")
print(f"torchaudio  : {torchaudio.__version__}")
print(f"CUDA        : {torch.version.cuda}")
print(f"GPU         : {torch.cuda.get_device_name(0)}")
print("torchvision : CUDA NMS OK")
print("torchaudio  : resample OK")

if importlib.util.find_spec("xformers") is None:
    print("xformers   : not installed (optional)")
else:
    import xformers
    from xformers.ops import memory_efficient_attention

    query = torch.randn(1, 2, 4, 8, device="cuda", dtype=torch.float16)
    key = torch.randn(1, 2, 4, 8, device="cuda", dtype=torch.float16)
    value = torch.randn(1, 2, 4, 8, device="cuda", dtype=torch.float16)
    attended = memory_efficient_attention(query, key, value)
    torch.cuda.synchronize()
    if attended.shape != query.shape:
        raise RuntimeError(f"xformers returned shape {tuple(attended.shape)}")

    print(f"xformers   : {getattr(xformers, '__version__', 'installed')}")
    print("xformers   : attention OK")
PY
 2>&1)"
then
    echo "[INFO] Existing PyTorch stack is healthy; skipping reinstall."
    echo "$EXISTING_STACK_INFO"
    exit 0
else
    echo "[INFO] Existing PyTorch stack is missing or unhealthy."
    echo "$EXISTING_STACK_INFO"
fi

# --------------------------------------------------
# Upgrade packaging tools
# --------------------------------------------------

echo
echo "=============================================="
echo " Updating pip"
echo "=============================================="

"$PYTHON" -m pip install --upgrade \
    pip \
    setuptools \
    wheel

# --------------------------------------------------
# Remove existing PyTorch stack
# --------------------------------------------------

echo
echo "=============================================="
echo " Removing existing PyTorch packages"
echo "=============================================="

"$PYTHON" -m pip uninstall -y \
    torch \
    torchvision \
    torchaudio \
    xformers \
    2>/dev/null || true

# --------------------------------------------------
# VOLTA
#
# V100 = SM 7.0
#
# PyTorch 2.14 is the final release with
# prebuilt CUDA wheels for Volta.
#
# CUDA 13.x does NOT support SM < 7.5.
# --------------------------------------------------

if [ "$ARCH" = "Volta" ]; then

    echo
    echo "=============================================="
    echo " VOLTA / V100 detected"
    echo "=============================================="

    echo
    echo "Installing:"
    echo "  PyTorch      : 2.14.0"
    echo "  TorchVision  : 0.29.0"
    echo "  CUDA wheel   : cu126"
    echo
    echo "Reason:"
    echo "  Volta SM 7.0 is no longer supported by"
    echo "  CUDA 13.x PyTorch wheels."
    echo

    "$PYTHON" -m pip install \
        "torch==2.14.0" \
        "torchvision==0.29.0" \
        --index-url https://download.pytorch.org/whl/cu126

    # Use the latest torchaudio wheel built for the same CUDA 12.6 runtime.
    # Keep the V100 torch stack intact and do not allow pip to downgrade it.
    "$PYTHON" -m pip install \
        "torchaudio==2.11.0+cu126" \
        --index-url https://download.pytorch.org/whl/cu126 \
        --no-deps

    "$PYTHON" -c 'import torchaudio; print(f"torchaudio {torchaudio.__version__}")'

    echo
    echo "V100 PyTorch installation completed."

# --------------------------------------------------
# MODERN GPUs
#
# Turing and newer:
# SM 7.5+
#
# CUDA 13.x is the current supported family.
# --------------------------------------------------

elif [ "$ARCH" != "Unknown" ]; then

    echo
    echo "=============================================="
    echo " MODERN NVIDIA GPU detected"
    echo "=============================================="

    echo
    echo "Architecture : $ARCH"
    echo "Compute      : $CC"
    echo
    echo "Installing current stable PyTorch CUDA 13.0"
    echo

    "$PYTHON" -m pip install \
        torch \
        torchvision \
        torchaudio \
        --index-url https://download.pytorch.org/whl/cu130

else

    echo
    echo "ERROR: Unsupported / unknown NVIDIA GPU:"
    echo "  $GPU_NAME"
    echo
    echo "Refusing to install a random PyTorch build."
    exit 1
fi

# --------------------------------------------------
# Remove accidental incompatible xformers
# --------------------------------------------------

echo
echo "=============================================="
echo " Checking xformers"
echo "=============================================="

if "$PYTHON" -m pip show xformers >/dev/null 2>&1; then
    echo "xformers detected."
    echo
    echo "WARNING: xformers may be incompatible with"
    echo "the selected PyTorch version."
    echo
    echo "Keeping installed version for now."
fi

# --------------------------------------------------
# Package consistency
# --------------------------------------------------

echo
echo "=============================================="
echo " PyTorch package versions"
echo "=============================================="

"$PYTHON" - <<'PY'
import importlib.util

mods = ["torch", "torchvision", "torchaudio"]

for name in mods:
    if importlib.util.find_spec(name):
        try:
            mod = __import__(name)
            print(f"{name:12s}: {getattr(mod, '__version__', 'unknown')}")
        except Exception as e:
            print(f"{name:12s}: IMPORT ERROR")
            print(f"  {e}")
    else:
        print(f"{name:12s}: not installed")
PY

# --------------------------------------------------
# CUDA test
# --------------------------------------------------

echo
echo "=============================================="
echo " CUDA TEST"
echo "=============================================="

"$PYTHON" - <<'PY'
import sys
import torch

print("PyTorch version :", torch.__version__)
print("Torch CUDA      :", torch.version.cuda)
print("CUDA available  :", torch.cuda.is_available())

if not torch.cuda.is_available():
    print()
    print("ERROR: CUDA is NOT available.")
    sys.exit(1)

print("GPU count       :", torch.cuda.device_count())

for i in range(torch.cuda.device_count()):
    name = torch.cuda.get_device_name(i)
    capability = torch.cuda.get_device_capability(i)
    print(f"GPU {i}           : {name}")
    print(f"Compute Capability: {capability[0]}.{capability[1]}")

# ------------------------------------------------
# Real CUDA kernel test
# ------------------------------------------------

print()
print("Running CUDA tensor test...")

device = torch.device("cuda:0")

a = torch.randn(
    (1024, 1024),
    device=device,
    dtype=torch.float32,
)

b = torch.randn(
    (1024, 1024),
    device=device,
    dtype=torch.float32,
)

c = a @ b

torch.cuda.synchronize()

print("CUDA tensor test : OK")
print("Result shape     :", tuple(c.shape))

# ------------------------------------------------
# Small convolution test
# ------------------------------------------------

print()
print("Running convolution test...")

conv = torch.nn.Conv2d(
    3,
    16,
    kernel_size=3,
    padding=1,
).cuda()

x = torch.randn(
    1,
    3,
    256,
    256,
    device=device,
)

y = conv(x)

torch.cuda.synchronize()

print("Conv test        : OK")
print("Output shape     :", tuple(y.shape))

print()
print("==============================================")
print(" CUDA / PyTorch TEST PASSED")
print("==============================================")
PY

# --------------------------------------------------
# Dependency check
# --------------------------------------------------

echo
echo "=============================================="
echo " pip dependency check"
echo "=============================================="

"$PYTHON" -m pip check || true

# --------------------------------------------------
# Final information
# --------------------------------------------------

echo
echo "=============================================="
echo " INSTALLATION COMPLETE"
echo "=============================================="

"$PYTHON" - <<'PY'
import importlib.util
import torch
import torchvision
import torchaudio

print()
print("PyTorch :", torch.__version__)
print("TorchVision :", torchvision.__version__)
print("TorchAudio  :", torchaudio.__version__)
print("CUDA    :", torch.version.cuda)
print("GPU     :", torch.cuda.get_device_name(0))
print("CC      :", torch.cuda.get_device_capability(0))

if importlib.util.find_spec("xformers") is not None:
    import xformers
    print("xformers :", getattr(xformers, "__version__", "installed"))
else:
    print("xformers : not installed (optional)")

print()
PY

echo "Python:"
echo "  $PYTHON"

echo
echo "IMPORTANT:"
echo "Run ComfyUI using the SAME venv:"
echo
echo "  $PYTHON $COMFY_DIR/main.py --listen 0.0.0.0 --port 8189"
echo
echo "Do NOT use:"
echo "  python3 $COMFY_DIR/main.py"
echo
echo "=============================================="