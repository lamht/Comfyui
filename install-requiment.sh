#!/bin/bash
set -euo pipefail

# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export COMFY_PATH="$SCRIPT_DIR/ComfyUI"

ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"

if ! grep -qx "export COMFY_PATH=\"$COMFY_PATH\"" ~/.bashrc 2>/dev/null; then
    echo "export COMFY_PATH=\"$COMFY_PATH\"" >> ~/.bashrc
fi

export COMFY_PATH

echo "Using ComfyUI at: $COMFY_PATH"

# ==============================
# CHECK COMFYUI
# ==============================
if [ ! -d "$COMFY_PATH" ]; then
    echo "ERROR: ComfyUI directory not found:"
    echo "$COMFY_PATH"
    exit 1
fi

# ==============================
# INSTALL CLOUDFLARED
# ==============================
wget -q -O cloudflared-linux-amd64.deb \
https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt-get install -f -y

# ==============================
# ADD NGINX REPO
# ==============================
curl -fsSL https://nginx.org/keys/nginx_signing.key \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" \
| sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null

# ==============================
# INSTALL PACKAGES
# ==============================
sudo apt update

sudo apt install -y \
curl \
git \
unzip \
gnupg2 \
ca-certificates \
lsb-release \
ubuntu-keyring \
build-essential \
libgl1-mesa-glx \
libglib2.0-0 \
python3 \
python3-dev \
python3-venv \
python3-pip \
lsof \
nginx

# ==============================
# CONFIG NGINX
# ==============================
if [ -f "$SCRIPT_DIR/nginx.conf" ]; then
    sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf
    sudo nginx -t
    sudo systemctl restart nginx
fi

# ==============================
# DOWNLOAD CUSTOM NODES
# ==============================
wget -O custom_nodes.zip \
"https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&dl=1"

unzip -o custom_nodes.zip -d "$COMFY_PATH"

# ==============================
# REMOVE OLD NODES
# ==============================
rm -rf "$COMFY_PATH/custom_nodes/rgthree-comfy" || true
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Crystools" || true
rm -rf "$COMFY_PATH/custom_nodes/comfyui-manager" || true
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Inpaint-CropAndStitch" || true
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Dwpose-Tensorrt" || true
rm -rf "$COMFY_PATH/custom_nodes/batch_image_loader" || true

# ==============================
# GIT SETTINGS
# ==============================
git config --global http.version HTTP/1.1
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 30
git config --global core.compression 0

# ==============================
# INSTALL REQUIRED NODES
# ==============================
git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git \
"$COMFY_PATH/custom_nodes/rgthree-comfy" || true

git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git \
"$COMFY_PATH/custom_nodes/comfyui-manager" || true

git clone --depth 1 https://github.com/crystian/ComfyUI-Crystools.git \
"$COMFY_PATH/custom_nodes/ComfyUI-Crystools" || true

git clone --depth 1 https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git \
"$COMFY_PATH/custom_nodes/ComfyUI-Inpaint-CropAndStitch" || true

git clone --depth 1 https://github.com/yuvraj108c/ComfyUI-Dwpose-Tensorrt.git \
"$COMFY_PATH/custom_nodes/ComfyUI-Dwpose-Tensorrt" || true

git clone --depth 1 https://github.com/orion4d/batch_image_loader.git \
"$COMFY_PATH/custom_nodes/batch_image_loader" || true

# ==============================
# CHECK PYTHON
# ==============================
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 not found"
    exit 1
fi

# ==============================
# CREATE VENV
# ==============================
if [ ! -d "$COMFY_PATH/venv" ]; then
    echo "[+] Creating virtual environment..."
    python3 -m venv "$COMFY_PATH/venv"
fi

echo "[+] Activating virtual environment..."
source "$COMFY_PATH/venv/bin/activate"

# ==============================
# UPDATE PIP
# ==============================
python -m pip install --upgrade \
pip \
setuptools \
wheel \
pip-tools

# ==============================
# INSTALL COMFYUI REQUIREMENTS
# ==============================
echo "[+] Installing ComfyUI requirements..."

pip install \
-r "$COMFY_PATH/requirements.txt" \
--prefer-binary

# ==============================
# BUILD CUSTOM NODE REQUIREMENTS
# ==============================
echo "[+] Collecting node requirements..."

find "$COMFY_PATH/custom_nodes" \
-type f \
-name requirements.txt \
-size +0c \
-exec sh -c 'cat "$1"; echo' _ {} \; \
> "$ALL_REQ"

# Optional fix if needed
# sed -i 's/transparent-backgrounddiffusers/transparent-background\ndiffusers/' "$ALL_REQ"

if pip-compile \
"$ALL_REQ" \
-o "$FINAL_REQ" \
--resolver=backtracking \
2>&1 | tee -a "$LOG_FILE"
then

    echo "[+] pip-compile success"

else

    echo "[!] pip-compile failed → fallback"
    cp "$ALL_REQ" "$FINAL_REQ"

fi

# ==============================
# INSTALL NODE REQUIREMENTS
# ==============================
pip install \
-r "$FINAL_REQ" \
--prefer-binary \
--upgrade-strategy only-if-needed \
2>&1 | tee -a "$LOG_FILE"

# ==============================
# VERIFY TORCH CUDA
# ==============================
if python -c "import torch; exit(0 if torch.cuda.is_available() else 1)"
then

    echo "PyTorch GPU OK"

else

    echo "PyTorch GPU not available -> reinstall"

    pip uninstall -y torch torchvision torchaudio || true

    pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

fi

# ==============================
# STOP OLD COMFYUI
# ==============================
kill -9 "$(lsof -t -i:8188)" 2>/dev/null || true

# ==============================
# START COMFYUI
# ==============================
cd "$COMFY_PATH"

nohup python main.py \
--listen 0.0.0.0 \
--port 8188 \
> "$SCRIPT_DIR/comfy.log" 2>&1 &

sleep 10

echo "[+] ComfyUI started"

# ==============================
# START CLOUDFLARED
# ==============================
pkill -f cloudflared || true

nohup cloudflared tunnel \
--url http://localhost:8188 \
> "$SCRIPT_DIR/cf.log" 2>&1 &

sleep 10

echo "=============================="
cat "$SCRIPT_DIR/cf.log" || true
echo "=============================="

echo "DONE"