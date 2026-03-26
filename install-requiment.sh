# SET COMFYUI path
# ==============================
COMFY_PATH="$(dirname "$0")/ComfyUI"

echo "Using ComfyUI at: $COMFY_PATH"

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
    pip install -r "$dir/requirements.txt" --upgrade --no-cache-dir
  fi
done

cd ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188