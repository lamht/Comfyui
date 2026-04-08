#!/bin/bash
set -e

# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMFY_PATH="$SCRIPT_DIR/ComfyUI"

# Persist COMFY_PATH for shell sessions
if ! grep -qx "export COMFY_PATH=\"$COMFY_PATH\"" ~/.bashrc 2>/dev/null; then
  echo "export COMFY_PATH=\"$COMFY_PATH\"" >> ~/.bashrc
fi
export COMFY_PATH

echo "Using ComfyUI at: $COMFY_PATH"

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
# MERGE REQUIREMENTS (SAFE)
# ==============================
echo "[+] Merge requirements..."

python3 - << EOF
import os
from collections import OrderedDict

comfy_path = "$COMFY_PATH"
req_files = []

main_req = os.path.join(comfy_path, "requirements.txt")
if os.path.isfile(main_req):
    req_files.append(main_req)

custom_dir = os.path.join(comfy_path, "custom_nodes")
if os.path.isdir(custom_dir):
    for d in os.listdir(custom_dir):
        f = os.path.join(custom_dir, d, "requirements.txt")
        if os.path.isfile(f):
            req_files.append(f)

packages = OrderedDict()

for file in req_files:
    with open(file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            name = line.split("==")[0].lower()
            packages[name] = line

out = os.path.join(comfy_path, "all.txt")
with open(out, "w") as f:
    for v in packages.values():
        f.write(v + "\\n")

print(f"[+] Generated {out}")
EOF

# ==============================
# INSTALL REQUIREMENTS (SYNC)
# ==============================
echo "[+] Installing Python packages..."

# đảm bảo pip sạch và mới
python3 -m pip install --upgrade pip setuptools wheel

# install với fallback resolver nếu cần
pip install -r "$COMFY_PATH/all.txt" \
  --prefer-binary \
  --no-cache-dir \
  --timeout 100 \
  --retries 5 \
  --use-deprecated=legacy-resolver \
  2>&1 | tee "$COMFY_PATH/install.log"

pip install -r "$COMFY_PATH/requirements.txt"

# ==============================
# INSTALL CLOUDFLARED
# ==============================
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
sudo dpkg -i cloudflared-linux-amd64.deb

# ==============================
# INSTALL NGINX
# ==============================
sudo apt update && \
sudo apt install -y nginx

# ==============================
# FIX TORCH
# ==============================
wait
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
# CONFIG NGINX
# ==============================
sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf && \
sudo nginx -t && \
sudo service nginx restart &

# ==============================
# START TUNNEL
# ==============================
nohup cloudflared tunnel --url http://localhost:8080 > cf.log 2>&1 &
sleep 5
cat cf.log

echo "DONE"
