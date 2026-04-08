#!/bin/bash
set -e

# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export COMFY_PATH="$SCRIPT_DIR/ComfyUI"

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
pip install -r "$COMFY_PATH/requirements.txt"

echo "[+] Installing custom_nodes requirements..."

for dir in "$COMFY_PATH/custom_nodes"/*; do
  if [ -f "$dir/requirements.txt" ]; then
    echo "[+] Installing: $dir"

    pip install -r "$dir/requirements.txt"
      2>&1 | tee -a "$COMFY_PATH/install.log"
  fi
done

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
nohup python3 main.py --listen 0.0.0.0 --port 8188 > comfy.log 2>&1 &

# ==============================
# START TUNNEL
# ==============================
nohup cloudflared tunnel --url http://localhost:8080 > cf.log 2>&1 &
sleep 5
cat cf.log

echo "DONE"
