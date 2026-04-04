# SET COMFYUI path
# ==============================
export COMFY_PATH="$(dirname "$0")/ComfyUI" >> ~/.bashrc

echo "Using ComfyUI at: $COMFY_PATH"

wget -O custom_nodes.zip "https://www.dropbox.com/scl/fi/molqh8osl8u1i9jyc3rv9/custom_nodes.zip?rlkey=3p4j51rinbhb13uvdw7b1dxk7&dl=1"
unzip -o custom_nodes.zip -d "$COMFY_PATH"
# ==============================
# ACTIVATE VENV (nếu có)
# ==============================
if [ -d "$COMFY_PATH/venv" ]; then
  source "$COMFY_PATH/venv/bin/activate"
fi

# ==============================
# INSTALL CORE
# ==============================
pip install -r "$COMFY_PATH/requirements.txt"

# ==============================
# INSTALL CUSTOM NODES
# ==============================
for dir in "$COMFY_PATH"/custom_nodes/*; do
  if [ -f "$dir/requirements.txt" ]; then
    echo "Installing $dir"
    pip install -r "$dir/requirements.txt" &
  fi
done

#INSTALL couldfare tunnel CLI
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &
sudo dpkg -i cloudflared-linux-amd64.deb &
wait

pip uninstall torch torchvision torchaudio -y
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

cd ComfyUI
# apt update
# apt install iproute2 -y
# kill -9 $(ss -tulnp | grep 8888 | grep -oP 'pid=\K\d+')
nohup python3 main.py --listen 0.0.0.0 --port 8188 &
nohup cloudflared tunnel --url http://localhost:8188 &
