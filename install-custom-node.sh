
#!/bin/bash
set -Eeuo pipefail

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

if [ -z "${COMFY_PATH:-}" ]; then
    export COMFY_PATH="$SCRIPT_DIR/ComfyUI"
    echo "[INFO] COMFY_PATH set to: $COMFY_PATH"
else
    echo "[INFO] COMFY_PATH already set: $COMFY_PATH"
fi

ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"

mkdir -p "$COMFY_PATH"

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
    lsof \
    nginx

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
# CONFIG NGINX
# ==============================
if [ -f "$SCRIPT_DIR/nginx.conf" ]; then

    cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf

    echo "[INFO] Testing nginx configuration..."

    nginx -t

    echo "[INFO] Starting/reloading nginx..."
    service nginx start || true
    nginx -s reload || echo "[WARNING] Failed to reload nginx, continuing..."

else

    echo "[INFO] nginx.conf not found, skip custom configuration"

fi

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

    local URL="${1:?Missing repository URL}"
    local DEST="${2:?Missing destination path}"
    local TAG="${3:-}"

    echo "[INFO] Installing: $DEST"

    mkdir -p "$(dirname "$DEST")"

    if [ -d "$DEST/.git" ]; then

        echo "[INFO] Already exists, updating..."

        git -C "$DEST" pull --ff-only || {
            echo "[WARNING] Failed to update $DEST"
            echo "[WARNING] Continuing with the existing checkout."
        }

    else

        local tag_arg=()

        if [ -n "$TAG" ]; then
            tag_arg=(--branch "$TAG")
        fi

        git clone \
            --depth 1 \
            "${tag_arg[@]}" \
            "$URL" \
            "$DEST" || {

            echo "[WARNING] Failed to clone $URL"
            echo "[WARNING] Continuing without this custom node."

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
    "https://github.com/crystian/ComfyUI-Crystools.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Crystools" \
    "V1.12.0"

clone_node \
    "https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Inpaint-CropAndStitch"

clone_node \
    "https://github.com/ltdrdata/ComfyUI-Manager.git" \
    "$COMFY_PATH/custom_nodes/ComfyUI-Manager" \
    "V3.32.5"

# ==============================
# PYTHON / VENV
# ==============================
PYTHON="python3"

echo "[INFO] Venv Python:"
"$PYTHON" --version

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

# Remove PyTorch / NumPy packages
# They are installed separately by install_torch_auto.sh.
grep -Eiv \
    '^[[:space:]]*(torch|torchvision|torchaudio|numpy)([<=>~!;[:space:]]|$)' \
    "$ALL_REQ" > "$ALL_REQ.filtered" || [ $? -eq 1 ]

mv "$ALL_REQ.filtered" "$ALL_REQ"

echo "[INFO] Requirements collected:"
wc -l "$ALL_REQ"

cp "$ALL_REQ" "$FINAL_REQ"

# ==============================
# INSTALL NODE REQUIREMENTS
# ==============================
echo "[INFO] Installing custom node requirements..."

# "$PYTHON" -m pip install \
#     -r "$FINAL_REQ" \
#     --prefer-binary \
#     2>&1 | tee -a "$LOG_FILE"

# ==============================
# STOP OLD COMFYUI
# ==============================
echo "[INFO] Stopping old ComfyUI..."

COMFY_PORT=8189

PIDS="$(lsof -t -i:"$COMFY_PORT" 2>/dev/null || true)"

if [ -n "$PIDS" ]; then

    while read -r PID; do

        if [ -n "$PID" ]; then
            echo "[INFO] Killing PID: $PID"
            kill -9 "$PID" || true
        fi

    done <<< "$PIDS"

    sleep 2

fi

# ==============================
# START COMFYUI
# ==============================
echo "[INFO] Starting ComfyUI..."

cd "$COMFY_PATH"

nohup "$PYTHON" \
    "$COMFY_PATH/main.py" \
    --listen 0.0.0.0 \
    --port "$COMFY_PORT" \
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

CLOUDFLARED_PIDS="$(
    pgrep -f 'cloudflared tunnel.*127\.0\.0\.1:9999' 2>/dev/null || true
)"

if [ -n "$CLOUDFLARED_PIDS" ]; then

    while read -r PID; do

        if [ -n "$PID" ]; then
            echo "[INFO] Killing Cloudflared PID: $PID"
            kill -9 "$PID" || true
        fi

    done <<< "$CLOUDFLARED_PIDS"

fi

# Forward port 9999 nginx -> ComfyUI 8189.
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
echo "ComfyUI        : http://0.0.0.0:8189"
echo "ComfyUI PID    : $COMFY_PID"
echo "Cloudflared PID: $CF_PID"
echo "ComfyUI log    : $SCRIPT_DIR/comfy.log"
echo "Cloudflared log: $SCRIPT_DIR/cf.log"
echo "======================================"