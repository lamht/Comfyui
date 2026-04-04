#!/bin/bash
set -e

# ==============================
# SET PATH
# ==============================
echo 'export COMFY_PATH="$(dirname "$0")/ComfyUI"' >> ~/.bashrc
export COMFY_PATH="$(dirname "$0")/ComfyUI"

echo "Using ComfyUI at: $COMFY_PATH"

# ==============================
# DOWNLOAD NODES
# ==============================
wget -O custom_nodes.zip "https://www.dropbox.com/scl/fi/molqh8osl8u1i9jyc3rv9/custom_nodes.zip?dl=1"
unzip -o custom_nodes.zip -d "$COMFY_PATH"

# ==============================
# ACTIVATE VENV
# ==============================
if [ -d "$COMFY_PATH/venv" ]; then
  source "$COMFY_PATH/venv/bin/activate"
fi

# ==============================
# GỘP REQUIREMENTS (an toàn)
# ==============================
> all.txt
for f in "$COMFY_PATH/requirements.txt" "$COMFY_PATH"/custom_nodes/*/requirements.txt; do
  if [ -f "$f" ]; then
    cat "$f" >> all.txt
    echo "" >> all.txt
  fi
done

# ==============================
# INSTALL (KHÔNG chạy song song)
# ==============================
pip install --upgrade -r all.txt --prefer-binary --no-cache-dir

# ==============================
# FIX TORCH
# ==============================
pip uninstall torch torchvision torchaudio -y || true
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# ==============================
# INSTALL CLOUDFLARED
# ==============================
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# ==============================
# INSTALL NGINX
# ==============================
sudo apt update
sudo apt install -y nginx

# ==============================
# START COMFYUI
# ==============================
cd "$COMFY_PATH"
nohup python3 main.py --listen 0.0.0.0 --port 8188 > comfy.log 2>&1 &

# ==============================
# CONFIG NGINX
# ==============================
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl restart nginx

# ==============================
# START TUNNEL
# ==============================
nohup cloudflared tunnel --url http://localhost:8080 --region apac > cf.log 2>&1 &
grep -o 'https://.*trycloudflare.com' cf.log | tail -n 1

echo "DONE"
