#!/bin/bash
set -e

# Load DB helper
source "$(dirname "$0")/db.sh"
init_db

# Args
STACK=""
TITLE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stack) STACK="$2"; shift ;;
        --title) TITLE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$STACK" || -z "$TITLE" ]]; then
    echo "Usage: ./create_sandbox.sh --stack <stack> --title <title>"
    exit 1
fi

# Naming: moltbot-essa-{lang}-{project_title}
# Normalize title to be url-safe
SAFE_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g' | xargs | tr ' ' '-')
CONTAINER_NAME="moltbot-essa-${STACK}-${SAFE_TITLE}"
VOLUME_NAME="${CONTAINER_NAME}-data"

echo "📦 Creating Sandbox: $CONTAINER_NAME"

# Check if exists
EXISTING=$(query_db "SELECT id FROM sandboxes WHERE name=?;" "$CONTAINER_NAME")
if [[ -n "$EXISTING" ]]; then
    echo "❌ Sandbox '$CONTAINER_NAME' already exists."
    exit 1
fi

# Define Stack Configs with Best Frameworks/Tools
# We use standard images but override entrypoints/commands to bootstrap.
# This assumes the agent has access to run these.
# For simplicity in this first pass, we use sleep loop or base image start, 
# then the agent is expected to 'docker exec' to scaffold.
# OR we can try to scaffold automatically. Let's do partial automated scaffolding.

DOCKER_IMAGE=""
INIT_CMD=""
INTERNAL_PORT="3000" # Default

case $STACK in
    nextjs)
        # Built-in bundler, fast installs
        DOCKER_IMAGE="oven/bun:1"
        INIT_CMD="bun create next-app . --typescript --no-eslint --no-tailwind --no-src-dir --import-alias '@/*' && bun dev --port 3000 --hostname 0.0.0.0"
        INTERNAL_PORT="3000"
        ;;
    fastapi)
        # UV is fast
        DOCKER_IMAGE="python:3.11-slim"
        # We need to install uv first
        INIT_CMD="pip install uv && uv venv && source .venv/bin/activate && uv pip install fastapi uvicorn[standard] && echo 'from fastapi import FastAPI\napp = FastAPI()\n@app.get(\"/\")\ndef read_root(): return {\"Hello\": \"World\"}' > main.py && uvicorn main:app --host 0.0.0.0 --port 8000"
        INTERNAL_PORT="8000"
        ;;
    laravel)
        DOCKER_IMAGE="bitnami/laravel:latest"
        INIT_CMD="" # Bitnami image handles start
        INTERNAL_PORT="8000"
        ;;
    *)
        echo "⚠️ Stack '$STACK' not fully automated yet. Using generic alpine."
        DOCKER_IMAGE="alpine:latest"
        INIT_CMD="sleep infinity"
        ;;
esac

# Create Volume
echo "Creating volume $VOLUME_NAME..."
docker volume create "$VOLUME_NAME" >/dev/null

# Run Container
# We map internal port to random host port or let Cloudflare handle it specifically.
# Since we use Tunnel, we don't strictly *need* to map ports to host, but it's useful for debug.
# We will NOT map to host to keep it clean, relying on 'cloudflared' inside the network or sidecar.
# For this implementation, we assume we use a tunnel for access.

echo "Running container..."
CID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -v "$VOLUME_NAME":/app \
    -w /app \
    "$DOCKER_IMAGE" \
    /bin/sh -c "$INIT_CMD")

echo "Container ID: $CID"

# Setup Tunnel (Simulated or Real)
# Ideally we run 'cloudflared tunnel' targeting the container IP + Port.
# Valid Cloudflare setup requires AUTH.
# For now, we will use 'trycloudflare' quick tunnels if no auth is present, or just log instructions.
# Assuming 'cloudflared' is installed on HOST and can see container IP?
# Better: Run cloudflared as a sidecar or Quick Tunnel.
# Quick Tunnel: cloudflared tunnel --url http://<container_ip>:<port>
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")
TUNNEL_LOG="/tmp/${CONTAINER_NAME}.tunnel.log"

echo "Starting Quick Tunnel for http://$CONTAINER_IP:$INTERNAL_PORT..."
# Run cloudflared in background, non-blocking
nohup cloudflared tunnel --url http://"$CONTAINER_IP":"$INTERNAL_PORT" > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

# Wait for URL
sleep 5
TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare\.com' "$TUNNEL_LOG" | head -n 1)

if [[ -z "$TUNNEL_URL" ]]; then
    TUNNEL_URL="(Tunnel failed to start or too slow: check $TUNNEL_LOG)"
fi

echo "🌍 Public URL: $TUNNEL_URL"

# Record in DB
query_db "INSERT INTO sandboxes (id, name, stack, port, tunnel_url, volume_path) VALUES (?, ?, ?, ?, ?, ?);" "$CID" "$CONTAINER_NAME" "$STACK" "$INTERNAL_PORT" "$TUNNEL_URL" "$VOLUME_NAME"

echo "✅ Sandbox '$CONTAINER_NAME' created and registered."
