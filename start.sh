# ==============================
# SCRIPT PATHS
# ==============================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export COMFY_PATH="$SCRIPT_DIR/ComfyUI"
ALL_REQ="$COMFY_PATH/all.txt"
FINAL_REQ="$COMFY_PATH/final.txt"
LOG_FILE="$COMFY_PATH/install.log"


# ==============================
# CHECK PYTHON & CREATE/ACTIVATE VENV
# ==============================
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is not installed. Please install it first."
    exit 1
fi

if [ ! -d "$COMFY_PATH/venv" ]; then
    echo "[+] Creating virtual environment..."
    python3 -m venv "$COMFY_PATH/venv" || {
        echo "ERROR: Failed to create virtual environment. Ensure python3-venv is installed."
        exit 1
    }
fi

echo "[+] Activating virtual environment..."
source "$COMFY_PATH/venv/bin/activate"

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
# START COMFYUI
# ==============================
cd "$COMFY_PATH"
nohup python3 main.py --listen 0.0.0.0 --port 8188 > $SCRIPT_DIR/comfy.log 2>&1 &