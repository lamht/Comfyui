# ============================================================
# ComfyUI + NVIDIA CUDA 12.4 / Ubuntu 22.04
# Python 3.10
# ============================================================

FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# ============================================================
# 1. System packages
# ============================================================

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Make "python" point to Python 3
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

# Upgrade pip tooling
RUN python3 -m pip install --upgrade \
    pip \
    setuptools \
    wheel

# ============================================================
# 2. ComfyUI
# ============================================================

WORKDIR /app

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI.git \
    /app/ComfyUI

# ============================================================
# 3. PyTorch CUDA 12.4
# ============================================================

RUN python3 -m pip install \
    --no-cache-dir \
    torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu124

# ============================================================
# 4. ComfyUI dependencies
# ============================================================

WORKDIR /app/ComfyUI

RUN python3 -m pip install \
    --no-cache-dir \
    -r requirements.txt

# ============================================================
# 5. Explicit Pydantic compatibility
# ============================================================

RUN python3 -m pip install \
    --no-cache-dir \
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
    -exec python3 -m pip install --no-cache-dir -r {} \;

# ============================================================
# 8. Re-apply critical dependencies
#    Custom nodes may change Pydantic/FastAPI versions
# ============================================================

RUN python3 -m pip install \
    --no-cache-dir \
    "pydantic>=2.10,<3" \
    "pydantic-settings>=2,<3"

# ============================================================
# 9. Optional OpenGL acceleration
# ============================================================

RUN python3 -m pip install \
    --no-cache-dir \
    PyOpenGL PyOpenGL_accelerate

# ============================================================
# 10. Verify Python / Torch / Pydantic
# ============================================================

RUN python3 - <<'PY'
import sys
import torch
import pydantic

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
# 11. Check dependencies
# ============================================================

RUN python3 -m pip check

# ============================================================
# 12. Startup scripts
# ============================================================

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
COPY hubfacedownload.sh /app/hubfacedownload.sh

RUN chmod +x \
    /app/entrypoint.sh \
    /app/hubfacedownload.sh

# ============================================================
# 13. ComfyUI port
# ============================================================

EXPOSE 8188

# ============================================================
# 14. Start
# ============================================================

ENTRYPOINT ["/app/entrypoint.sh"]