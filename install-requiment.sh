#!/bin/bash
set -euo pipefail

# ==============================
# ROOT CHECK
# ==============================
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Please run this script as root."
    exit 1
fi

# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export COMFY_PATH="$SCRIPT_DIR/ComfyUI"

ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"

echo "Using ComfyUI at: $COMFY_PATH"

# ==============================
# SAVE COMFY_PATH
# ==============================
if ! grep -Fqx "export COMFY_PATH=\"$COMFY_PATH\"" /root/.bashrc 2>/dev/null; then
    echo "export COMFY_PATH=\"$COMFY_PATH\"" >> /root/.bashrc
fi

# ==============================
# CHECK COMFYUI
# ==============================
if [ ! -d "$COMFY_PATH" ]; then
    echo "[ERROR] ComfyUI directory not found:"
    echo "$COMFY_PATH"
    exit 1
fi

# ==============================
# FIX BROKEN NGINX REPOSITORY
# ==============================
echo "[INFO] Cleaning old nginx repository..."

rm -f /etc/apt/sources.list.d/nginx.list

# ==============================
# INITIAL APT UPDATE
# ==============================
echo "[INFO] Updating apt..."

apt-get update

# ==============================
# INSTALL APT PREREQUISITES
# ==============================
echo "[INFO] Installing prerequisites..."

apt-get install -y \
    curl \
    wget \
    gnupg2 \
    ca-certificates \
    lsb-release \
    ubuntu-keyring \
    software-properties-common \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    git \
    unzip \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    lsof

# ==============================
# INSTALL CLOUDFLARED
# ==============================
echo "[INFO] Installing cloudflared..."

CLOUDFLARED_DEB="/tmp/cloudflared-linux-amd64.deb"

wget -q -O "$CLOUDFLARED_DEB" \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"

dpkg -i "$CLOUDFLARED_DEB" || apt-get install -f -y

rm -f "$CLOUDFLARED_DEB"

cloudflared --version

# ==============================
# ADD NGINX REPO
# ==============================
echo "[INFO] Adding nginx repository..."

NGINX_CODENAME="$(lsb_release -cs)"

echo "[INFO] Ubuntu codename: $NGINX_CODENAME"

curl -fsSL https://nginx.org/keys/nginx_signing.key | \
    gpg --dearmor --yes \
    -o /usr/share/keyrings/nginx-archive-keyring.gpg

cat > /etc/apt/sources.list.d/nginx.list <<EOF
deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu ${NGINX_CODENAME} nginx
EOF

cat /etc/apt/sources.list.d/nginx.list

# ==============================
# UPDATE APT
# ==============================
apt-get update

# ==============================
# INSTALL NGINX
# ==============================
apt-get install -y nginx

# ==============================
# CONFIG NGINX
# ==============================
if [ -f "$SCRIPT_DIR/nginx.conf" ]; then

    cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf

    echo "[INFO] Testing nginx configuration..."
    nginx -t

    echo "[INFO] Starting/reloading nginx..."

    nginx -s reload 2>/dev/null || nginx

else

    echo "[INFO] nginx.conf not found, skip custom configuration"

fi

# ==============================
# DOWNLOAD CUSTOM NODES
# ==============================
echo "[INFO] Downloading custom nodes..."

CUSTOM_NODES_ZIP="/tmp/custom_nodes.zip"

wget -q -O "$CUSTOM_NODES_ZIP" \
    "https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&dl=1"

unzip -o "$CUSTOM_NODES_ZIP" -d "$COMFY_PATH"

rm -f "$CUSTOM_NODES_ZIP"

# ==============================
# REMOVE OLD NODES
# ==============================
echo "[INFO] Removing old custom nodes..."

rm -rf "$COMFY_PATH/custom_nodes/rgthree-comfy"
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Crystools"
rm -rf "$COMFY_PATH/custom_nodes/comfyui-manager"
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Inpaint-CropAndStitch"
rm -rf "$COMFY_PATH/custom_nodes/ComfyUI-Dwpose-Tensorrt"
rm -rf "$COMFY_PATH/custom_nodes/batch_image_loader"

# ==============================
# GIT SETTINGS
# ==============================
echo "[INFO] Configuring git..."

git config --global http.version HTTP/1.1
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 30
git config --global core.compression 0

# ==============================
# CUSTOM NODE FUNCTION
# ==============================
clone_node() {

    local URL="$1"
    local DEST="$2"

    echo "[INFO] Installing: $DEST"

    if [ -d "$DEST/.git" ]; then

        echo "[INFO] Already exists, updating..."

        git -C "$DEST" pull --ff-only || true

    else

        git clone --depth 1 "$URL" "$DEST" || {
            echo "[WARNING] Failed to clone $URL"
            echo "[WARNING] Continuing..."
        }

    fi
}

# ==============================
# INSTALL REQUIRED NODES
# ==============================
clone_node \
    "https://github.com/rgthree/rgthree-comfy.git" \
    "$COMFY_PATH/custom_nodes/rgthree-comfy"

clone_node \
    "https://github.com/ltdrdata/ComfyUI-Manager.git" \
    "$COMFY_PATH/custom_nodes/comfyui-manager"

clone_node \
    "https://github.com/crystian/ComfyUI-Crystools.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Crystools"

clone_node \
    "https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Inpaint-CropAndStitch"

clone_node \
    "https://github.com/yuvraj108c/ComfyUI-Dwpose-Tensorrt.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Dwpose-Tensorrt"

clone_node \
    "https://github.com/orion4d/batch_image_loader.git" \
    "$COMFY_PATH/custom_nodes/batch_image_loader"

# ==============================
# PYTHON / VENV
# ==============================
PYTHON="$COMFY_PATH/venv/bin/python"

if [ ! -x "$PYTHON" ]; then

    echo "[INFO] Creating virtual environment..."

    python3 -m venv "$COMFY_PATH/venv"

fi

echo "[INFO] Venv Python:"
"$PYTHON" --version

# ==============================
# UPGRADE PIP
# ==============================
echo "[INFO] Upgrading pip..."

"$PYTHON" -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    pip-tools

# ==============================
# COMFYUI REQUIREMENTS
# ==============================
echo "[INFO] Installing ComfyUI requirements..."

"$PYTHON" -m pip install \
    -r "$COMFY_PATH/requirements.txt" \
    --prefer-binary

# ==============================
# COLLECT NODE REQUIREMENTS
# ==============================
echo "[INFO] Collecting custom node requirements..."

find "$COMFY_PATH/custom_nodes" \
    -type f \
    -name requirements.txt \
    -size +0c \
    -exec sh -c 'cat "$1"; echo' _ {} \; \
    > "$ALL_REQ"

echo "[INFO] Requirements collected:"
wc -l "$ALL_REQ"

# ==============================
# COMPILE REQUIREMENTS
# ==============================
echo "[INFO] Running pip-compile..."

if pip-compile \
    "$ALL_REQ" \
    -o "$FINAL_REQ" \
    --resolver=backtracking \
    2>&1 | tee -a "$LOG_FILE"
then

    echo "[INFO] pip-compile success"

else

    echo "[WARNING] pip-compile failed."
    echo "[WARNING] Using raw requirements.txt"

    cp "$ALL_REQ" "$FINAL_REQ"

fi

# ==============================
# INSTALL NODE REQUIREMENTS
# ==============================
echo "[INFO] Installing custom node requirements..."

"$PYTHON" -m pip install \
    -r "$FINAL_REQ" \
    --prefer-binary \
    --upgrade-strategy only-if-needed \
    2>&1 | tee -a "$LOG_FILE"

# ==============================
# SQLALCHEMY
# ==============================
echo "[INFO] Installing SQLAlchemy..."

"$PYTHON" -m pip install sqlalchemy

# ==============================
# FIX PYTORCH / CUDA
# ==============================
echo
echo "======================================"
echo " FIXING PYTORCH / CUDA"
echo "======================================"

chmod +x "$SCRIPT_DIR/install_torch_auto.sh"

"$SCRIPT_DIR/install_torch_auto.sh"

# ==============================
# FINAL PYTORCH CHECK
# ==============================
echo
echo "======================================"
echo " FINAL PYTORCH CHECK"
echo "======================================"

"$PYTHON" - <<'PY'
import torch

print("Torch:", torch.__version__)
print("CUDA runtime:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is NOT available")

print("GPU:", torch.cuda.get_device_name(0))
print("Compute Capability:", torch.cuda.get_device_capability(0))

x = torch.randn(1, 3, 64, 64, device="cuda")
conv = torch.nn.Conv2d(3, 16, 3).cuda()
y = conv(x)

torch.cuda.synchronize()

print("CUDA kernel test: OK")
print("Output:", y.shape)
PY

# ==============================
# STOP OLD COMFYUI
# ==============================
echo "[INFO] Stopping old ComfyUI..."

PIDS="$(lsof -t -i:8188 2>/dev/null || true)"

if [ -n "$PIDS" ]; then
    kill -9 $PIDS || true
    sleep 2
fi

# ==============================
# START COMFYUI
# ==============================
echo "[INFO] Starting ComfyUI..."

cd "$COMFY_PATH"

export PYTHONUNBUFFERED=1
export PYTHONPATH="$COMFY_PATH"
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

nohup "$PYTHON" \
    "$COMFY_PATH/main.py" \
    --listen 0.0.0.0 \
    --port 8189 \
    > "$SCRIPT_DIR/comfy.log" 2>&1 &

COMFY_PID=$!

echo "[INFO] ComfyUI PID: $COMFY_PID"

sleep 10

if kill -0 "$COMFY_PID" 2>/dev/null; then

    echo "[INFO] ComfyUI started successfully."

else

    echo "[ERROR] ComfyUI failed to start."
    tail -100 "$SCRIPT_DIR/comfy.log"
    exit 1

fi

# ==============================
# START CLOUDFLARED
# ==============================
echo "[INFO] Starting Cloudflared..."

pkill -x cloudflared 2>/dev/null || true
# foward port 9999 nginx -> comfyui 8189
nohup cloudflared tunnel \
    --url http://127.0.0.1:9999 \
    > "$SCRIPT_DIR/cf.log" 2>&1 &

CF_PID=$!

echo "[INFO] Cloudflared PID: $CF_PID"

sleep 10

echo
echo "=============================="
echo "Cloudflared log:"
cat "$SCRIPT_DIR/cf.log" || true
echo "=============================="

if kill -0 "$CF_PID" 2>/dev/null; then
    echo "[INFO] Cloudflared started successfully."
else
    echo "[WARNING] Cloudflared process exited."
fi

echo
echo "======================================"
echo " INSTALLATION COMPLETED"
echo "======================================"
echo "ComfyUI       : http://0.0.0.0:8189"
echo "ComfyUI PID   : $COMFY_PID"
echo "Cloudflared PID: $CF_PID"
echo "ComfyUI log   : $SCRIPT_DIR/comfy.log"
echo "Cloudflared log: $SCRIPT_DIR/cf.log"
echo "======================================"