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
wget -O custom_nodes.zip "https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&st=8lx5fxip&dl=0"
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

# Deduplicate and keep last version
sort all.txt | uniq -w 20 > all_dedup.txt
mv all_dedup.txt all.txt

# ==============================
# INSTALL
# ==============================
pip install --upgrade -r all.txt --prefer-binary --no-cache-dir 2>&1 | tee install.log &

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
sudo cp $(dirname "$0")/nginx.conf /etc/nginx/nginx.conf
sudo nginx -t
sudo service nginx restart

# ==============================
# START TUNNEL
# ==============================
nohup cloudflared tunnel --url http://localhost:8188 > cf.log 2>&1 &
cat cf.log

echo "DONE"
