#!/bin/bash
set -e
source "$(dirname "$0")/db.sh"
init_db

NAME="$1"

if [[ -z "$NAME" ]]; then
    echo "Usage: $0 <sandbox_name>"
    exit 1
fi

# Get info
ID=$(query_db "SELECT id FROM sandboxes WHERE name=?;" "$NAME")

if [[ -z "$ID" ]]; then
    echo "❌ Sandbox '$NAME' not found in registry."
    exit 1
fi

echo "🗑️ Deleting Sandbox: $NAME ($ID)"

# Stop/Remove Container
docker rm -f "$ID" || echo "Warning: Container might already be gone."

# Remove from DB
query_db "DELETE FROM sandboxes WHERE id=?;" "$ID"

echo "✅ Sandbox deleted."
# Note: We purposely do NOT delete the volume by default to preserve data safety 
# unless explicitly requested (feature for later).
