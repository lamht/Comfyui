# Sử dụng Base Image NVIDIA CUDA 12.4 / Ubuntu 22.04 (môi trường tối ưu cho PyTorch hiện tại)
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 1. Cài đặt các gói hệ thống cần thiết
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Clone ComfyUI base
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git .

# 3. Cài đặt PyTorch hỗ trợ CUDA
RUN pip3 install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124

# 4. Cài đặt dependencies cho ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Clone các Custom Nodes theo yêu cầu
WORKDIR /app/custom_nodes
RUN git clone --depth 1 https://github.com/lamht/ComfyUI-LoadNextImage.git && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone --depth 1 https://github.com/crystian/ComfyUI-Crystools.git && \
    git clone --depth 1 https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git

# 6. Tự động tìm và cài đặt requirements.txt của các custom node (nếu có)
RUN find . -maxdepth 2 -name "requirements.txt" -exec pip3 install --no-cache-dir -r {} \;

WORKDIR /app

# 8. Cấu hình script khởi chạy
COPY entrypoint.sh /app/entrypoint.sh
COPY hubfacedownload.sh /app/hubfacedownload.sh
RUN chmod +x /app/entrypoint.sh
RUN chmod +x /app/hubfacedownload.sh

EXPOSE 8188

ENTRYPOINT ["/app/entrypoint.sh"]