FROM python:3.10-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git curl wget build-essential libgl1 libglib2.0-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG SCRIPT_DIR="/app"
ENV SCRIPT_DIR="/app"
ARG COMFY_PATH="$SCRIPT_DIR/ComfyUI"
ARG ALL_REQ="$COMFY_PATH/all.txt"
ARG FINAL_REQ="$COMFY_PATH/final.txt"
ARG LOG_FILE="$COMFY_PATH/install.log"

WORKDIR /app
COPY . /app

RUN wget -O custom_nodes.zip "https://www.dropbox.com/scl/fi/ccabj5q3p8go0ht8fkwif/custom_nodes.zip?rlkey=6lh2ok89q00deqm0fgptdv1m7&st=8lx5fxip&dl=0"
RUN unzip -o custom_nodes.zip -d "$COMFY_PATH"

# Install pip requirements
# Install pip and project requirements (runs the same logic as install-requiment.sh)
RUN python3 -m pip install --upgrade pip setuptools wheel \
 && pip install -r "$COMFY_PATH/requirements.txt" --prefer-binary \
 && pip install pip-tools \
 && { find "$COMFY_PATH/custom_nodes" -type f -name "requirements.txt" -size +0c -exec sh -c 'cat "$1"; echo' _ {} \; ; } > "$ALL_REQ" \
 && if pip-compile "$ALL_REQ" -o "$FINAL_REQ" --resolver=backtracking 2>&1 | tee -a "$LOG_FILE"; then echo "[+] Compile success"; else echo "[!] Compile failed — falling back to all.txt" && cp "$ALL_REQ" "$FINAL_REQ"; fi \
 && pip install -r "$FINAL_REQ" --prefer-binary --upgrade-strategy only-if-needed 2>&1 | tee -a "$LOG_FILE"

RUN pip uninstall torch torchvision torchaudio -y || true
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# Copy entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8188

ENV PYTHONUNBUFFERED=1
CMD ["/usr/local/bin/docker-entrypoint.sh"]
