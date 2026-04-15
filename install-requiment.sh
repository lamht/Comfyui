#!/bin/bash
set -e

# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export COMFY_PATH="$SCRIPT_DIR/ComfyUI"
ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"

# Persist COMFY_PATH for shell sessions
if ! grep -qx "export COMFY_PATH=\"$COMFY_PATH\"" ~/.bashrc 2>/dev/null; then
  echo "export COMFY_PATH=\"$COMFY_PATH\"" >> ~/.bashrc
fi
export COMFY_PATH

echo "Using ComfyUI at: $COMFY_PATH"

# ==============================
# INSTALL CLOUDFLARED AND NGINX
# ==============================
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
sudo dpkg -i cloudflared-linux-amd64.deb && \
sudo apt update && \
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring && \
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null && \
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" \
| sudo tee /etc/apt/sources.list.d/nginx.list && \
sudo apt update && \
sudo apt install -y nginx && \
sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf && \
sudo nginx -t && \
sudo service nginx restart &

# ==============================
# DOWNLOAD NODES
# ==============================
wget -O custom_nodes.zip "https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&st=8lx5fxip&dl=0"
unzip -o custom_nodes.zip -d "$COMFY_PATH"

# ==============================
# ACTIVATE VENV
# ==============================
if [ -d "$COMFY_PATH/venv" ]; then
  source "$COMFY_PATH/venv/bin/activate"
fi

# ==============================
# INSTALL REQUIREMENTS (SYNC)
# ==============================
echo "[+] Installing Python packages..."

python3 -m pip install --upgrade pip setuptools wheel
pip install -r "$COMFY_PATH/requirements.txt" --prefer-binary

echo "[+] Installing custom_nodes requirements..."

{
  find "$COMFY_PATH/custom_nodes" -type f -name "requirements.txt" -size +0c \
    -exec sh -c 'cat "$1"; echo' _ {} \;
} > "$ALL_REQ"
# sed -i 's/transparent-backgrounddiffusers/transparent-background\ndiffusers/' "$ALL_REQ"
pip install pip-tools

if pip-compile "$ALL_REQ" -o "$FINAL_REQ" --resolver=backtracking \
  2>&1 | tee -a "$LOG_FILE"; then

  echo "[+] Compile success"

else
  echo "[!] Compile failed → fallback dùng all.txt"
  cp "$ALL_REQ" "$FINAL_REQ"
fi

pip install -r "$FINAL_REQ" \
  --prefer-binary \
  --upgrade-strategy only-if-needed \
  2>&1 | tee -a "$LOG_FILE"

# ==============================
# FIX TORCH
# ==============================
if [ $? -ne 0 ]; then
  echo "ERROR: pip install failed. Check install.log"
  exit 1
fi
pip uninstall torch torchvision torchaudio -y || true
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130


# ==============================
# START COMFYUI
# ==============================
cd "$COMFY_PATH"
nohup python3 main.py --listen 0.0.0.0 --port 8188 > $SCRIPT_DIR/comfy.log 2>&1 &

# ==============================
# START TUNNEL
# ==============================
nohup cloudflared tunnel --url http://localhost:9999 > $SCRIPT_DIR/cf.log 2>&1 &
sleep 5
cat $SCRIPT_DIR/cf.log

echo "DONE"
