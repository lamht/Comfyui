# ============================================================
# ComfyUI + NVIDIA CUDA 13.0 / Ubuntu 24.04
# Python 3.12
# ============================================================

FROM nvidia/cuda:13.0.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PATH="/opt/venv/bin:${PATH}"

# ============================================================
# 1. System packages
# ============================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
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
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv \
    && python -m pip install --upgrade pip setuptools wheel

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

RUN python -m pip install \
    --index-url https://download.pytorch.org/whl/cu130 \
    torch torchvision torchaudio

# ============================================================
# 4. ComfyUI dependencies
# ============================================================

WORKDIR /app/ComfyUI

RUN python -m pip install -r requirements.txt

# ============================================================
# 5. Explicit Pydantic compatibility
# ============================================================

RUN python -m pip install \
    "pydantic>=2.10,<3" \
    "pydantic-settings>=2,<3"

# ============================================================
# 6. Custom Nodes
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
# 7. Custom node requirements
# ============================================================

RUN find /app/ComfyUI/custom_nodes \
    -maxdepth 3 \
    -type f \
    -name "requirements.txt" \
    -print \
    -exec python -m pip install -r {} \;

# ============================================================
# 8. Re-apply critical dependencies
#    Custom nodes may change Pydantic/FastAPI versions
# ============================================================

RUN python -m pip install \
    "pydantic>=2.10,<3" \
    "pydantic-settings>=2,<3"

# ============================================================
# 9. Optional OpenGL acceleration
# ============================================================

RUN python -m pip install PyOpenGL PyOpenGL_accelerate

# ============================================================
# 10. Verify Python / Torch / Pydantic
# ============================================================

RUN python - <<'PY'
import sys
import torch
import pydantic

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
PY

# ============================================================
# 11. Verify comfy-kitchen operations used by FP8 and W4A8 paths
# ============================================================

RUN python - <<'PY'
import comfy_kitchen
from comfy_kitchen.tensor import w4a8_int8_linear

if not callable(getattr(comfy_kitchen, "stochastic_rounding_fp8", None)):
    raise RuntimeError("comfy-kitchen does not expose stochastic_rounding_fp8")
if not callable(w4a8_int8_linear):
    raise RuntimeError("comfy-kitchen does not expose w4a8_int8_linear")

print("comfy-kitchen FP8 stochastic rounding and W4A8 linear APIs are available")
PY

# ============================================================
# 12. Check dependencies
# ============================================================

RUN python -m pip check

# ============================================================
# 13. Startup scripts
# ============================================================

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
COPY hubfacedownload.sh /app/hubfacedownload.sh

RUN chmod +x \
    /app/entrypoint.sh \
    /app/hubfacedownload.sh

# ============================================================
# 14. ComfyUI port
# ============================================================

EXPOSE 8188

# ============================================================
# 15. Start
# ============================================================

ENTRYPOINT ["/app/entrypoint.sh"]