# syntax=docker/dockerfile:1

# ============================================================
# ComfyUI + NVIDIA CUDA 13.0 / Ubuntu 24.04
# Python 3.12
# ============================================================

FROM nvidia/cuda:13.0.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/opt/venv/bin:${PATH}"

# ============================================================
# 1. System packages
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    build-essential \
    && python3 -m venv /opt/venv \
    && python -m pip install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# 2. ComfyUI
# ============================================================

WORKDIR /app

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI.git \
    /app/ComfyUI

# ============================================================
# 3. PyTorch CUDA 13.0
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install \
    --index-url https://download.pytorch.org/whl/cu130 \
    torch torchvision torchaudio

# ============================================================
# 4. ComfyUI dependencies
# ============================================================

WORKDIR /app/ComfyUI

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install -r requirements.txt \
    && python -m pip install \
    "pydantic>=2.10,<3" \
    "pydantic-settings>=2,<3" \
    PyOpenGL PyOpenGL_accelerate

# ============================================================
# 5. Custom Nodes
# ============================================================

WORKDIR /app/ComfyUI/custom_nodes

RUN git clone --depth 1 \
        https://github.com/lamht/ComfyUI-LoadNextImage.git \
    && git clone --depth 1 \
        https://github.com/rgthree/rgthree-comfy.git \
    && git clone --depth 1 \
        https://github.com/ltdrdata/ComfyUI-Manager.git \
    && git clone --depth 1 \
        https://github.com/crystian/ComfyUI-Crystools.git \
    && git clone --depth 1 \
        https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git

# ============================================================
# 6. Custom node requirements
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    find /app/ComfyUI/custom_nodes \
    -maxdepth 3 \
    -type f \
    -name "requirements.txt" \
    -print \
    -exec python -m pip install -r {} \;

# ============================================================
# 7. Re-apply critical dependencies
#    Custom nodes may change Pydantic/FastAPI versions
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install \
    "pydantic>=2.10,<3" \
    "pydantic-settings>=2,<3"

# ============================================================
# 8. Verify Python / Torch / Pydantic
# ============================================================

RUN python -m pip check \
    && python - <<'PY'
import sys
import torch
import pydantic
import comfy_kitchen
from comfy_kitchen.tensor import w4a8_int8_linear

if sys.version_info < (3, 12):
    raise RuntimeError(f"Expected Python 3.12+, found {sys.version}")
if torch.version.cuda != "13.0":
    raise RuntimeError(f"Expected PyTorch CUDA 13.0, found {torch.version.cuda}")

print("=" * 60)
print("Python:", sys.version)
print("PyTorch:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
print("Pydantic:", pydantic.__version__)
print("Pydantic path:", pydantic.__file__)

from pydantic import BaseModel, Field

class TestModel(BaseModel):
    url: str | None = Field(None)

print("Pydantic Field test:", TestModel())
print("=" * 60)

if not callable(getattr(comfy_kitchen, "stochastic_rounding_fp8", None)):
    raise RuntimeError("comfy-kitchen does not expose stochastic_rounding_fp8")
if not callable(w4a8_int8_linear):
    raise RuntimeError("comfy-kitchen does not expose w4a8_int8_linear")

print("comfy-kitchen FP8 stochastic rounding and W4A8 linear APIs are available")
PY

# ============================================================
# 9. Startup scripts
# ============================================================

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
COPY hubfacedownload.sh /app/hubfacedownload.sh

RUN chmod +x \
    /app/entrypoint.sh \
    /app/hubfacedownload.sh

# ============================================================
# 10. ComfyUI port
# ============================================================

EXPOSE 8188

# ============================================================
# 11. Start
# ============================================================

ENTRYPOINT ["/app/entrypoint.sh"]