
#!/bin/bash

set -e

# ==========================================
# CONFIG
# ==========================================

SOURCE="/app/ComfyUI/output"
REMOTE="gdrive"
INTERVAL=30

# Google Drive OAuth token from environment
if [ -z "${GDRIVE_TOKEN:-}" ]; then
    echo "[ERROR] GDRIVE_TOKEN is not set!"
    exit 1
fi

# ==========================================
# INSTALL RCLONE
# ==========================================

if ! command -v rclone >/dev/null 2>&1; then
    echo "[INSTALL] Installing rclone..."
    apt-get update
    apt-get install -y curl unzip
    curl -fsSL https://rclone.org/install.sh | bash
fi

# ==========================================
# CONFIGURE GOOGLE DRIVE
# ==========================================

mkdir -p /root/.config/rclone

cat > /root/.config/rclone/rclone.conf <<EOF
[gdrive]
type = drive
scope = drive
token = ${GDRIVE_TOKEN}
EOF

chmod 600 /root/.config/rclone/rclone.conf

# ==========================================
# CHECK SOURCE
# ==========================================

if [ ! -d "$SOURCE" ]; then
    echo "[ERROR] Source not found: $SOURCE"
    exit 1
fi

# ==========================================
# TEST GOOGLE DRIVE
# ==========================================

echo "[INFO] Testing Google Drive..."

rclone lsd "$REMOTE:"

echo "[SUCCESS] Google Drive connected!"

# ==========================================
# DESTINATION
# ==========================================

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEST="${REMOTE}:Comfyui_output_${TIMESTAMP}"

echo "[INFO] Destination: $DEST"

# ==========================================
# SYNC LOOP
# ==========================================

while true; do

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync started..."

    rclone copy "$SOURCE" "$DEST" \
        --create-empty-src-dirs \
        --transfers 4 \
        --checkers 8 \
        --drive-chunk-size 64M \
        --log-level INFO \
        --stats 10s

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync finished (exit: $?)"

    sleep "$INTERVAL"

done
