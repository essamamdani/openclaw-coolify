#!/usr/bin/env bash
set -e

# =============================================================================
# OpenClaw Bootstrap Script v2.1 (Robust Edition)
# =============================================================================

OPENCLAW_STATE="/home/node/.openclaw"
CONFIG_FILE="$OPENCLAW_STATE/openclaw.json"
TEMPLATE_FILE="/app/openclaw.template.json"
WORKSPACE_DIR="/home/node/openclaw-workspace"

echo "🦞 OpenClaw Bootstrap Starting..."

# Ensure directory structure
mkdir -p "$OPENCLAW_STATE" "$WORKSPACE_DIR"
mkdir -p "$OPENCLAW_STATE/credentials"
mkdir -p "$OPENCLAW_STATE/agents/main/sessions"
mkdir -p "$OPENCLAW_STATE/python" "$OPENCLAW_STATE/npm"
chmod 700 "$OPENCLAW_STATE"
chmod 700 "$OPENCLAW_STATE/credentials"

# -----------------------------------------------------------------------------
# gog CLI: Persistent Configuration
# -----------------------------------------------------------------------------
mkdir -p "$OPENCLAW_STATE/gogcli"
# Note: /home/node/.config is tmpfs, so we can't create symlinks there
# Instead, set GOG_CONFIG_DIR environment variable
export GOG_CONFIG_DIR="$OPENCLAW_STATE/gogcli"

if [ -n "$GOOGLE_CALENDAR_CREDENTIALS_JSON" ]; then
  echo "$GOOGLE_CALENDAR_CREDENTIALS_JSON" > "$OPENCLAW_STATE/gogcli/credentials.json"
  chmod 600 "$OPENCLAW_STATE/gogcli/credentials.json"
  echo "✅ gog credentials configured"
fi

if [ -n "$GOG_KEYRING_PASSWORD" ]; then
  export GOG_KEYRING_PASSWORD
  echo "✅ gog keyring password set"
fi

# -----------------------------------------------------------------------------
# Configuration Generation (Template Based)
# -----------------------------------------------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Generating openclaw.json from template..."
  TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 24 2>/dev/null || node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")}"
  
  if [ -f "$TEMPLATE_FILE" ]; then
    sed "s/{{ACCESS_TOKEN}}/$TOKEN/g" "$TEMPLATE_FILE" > "$CONFIG_FILE"
  else
    # Minimal fallback
    cat >"$CONFIG_FILE" <<EOF
{
  "gateway": { "port": 18789, "auth": { "mode": "token", "token": "$TOKEN" } },
  "agents": { "defaults": { "workspace": "$WORKSPACE_DIR" } }
}
EOF
  fi
  echo "✅ Configuration generated"
else
  # Update token if OPENCLAW_GATEWAY_TOKEN is set
  if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    echo "Updating gateway token from environment variable..."
    python3 << PYEOF
import json
try:
    with open("$CONFIG_FILE", "r") as f:
        config = json.load(f)
    if "gateway" in config and "auth" in config["gateway"]:
        config["gateway"]["auth"]["token"] = "$OPENCLAW_GATEWAY_TOKEN"
        # Also update bind setting if OPENCLAW_GATEWAY_BIND is set
        if "$OPENCLAW_GATEWAY_BIND":
            config["gateway"]["bind"] = "$OPENCLAW_GATEWAY_BIND"
        # Update trustedProxies if GATEWAY_TRUSTED_PROXIES is set
        if "$GATEWAY_TRUSTED_PROXIES":
            proxies = "$GATEWAY_TRUSTED_PROXIES".split(",")
            config["gateway"]["trustedProxies"] = [p.strip() for p in proxies]
        with open("$CONFIG_FILE", "w") as f:
            json.dump(config, f, indent=2)
        print("✅ Gateway token updated")
except Exception as e:
    print(f"⚠️ Token update failed: {e}")
PYEOF
  fi
fi

# -----------------------------------------------------------------------------
# Fix Dynamic Sandbox Network (Restored from v1.0)
# -----------------------------------------------------------------------------
NETWORK_NAME=$(docker network ls --filter name=openclaw-internal --format "{{.Name}}" 2>/dev/null | head -1)
if [ -n "$NETWORK_NAME" ]; then
  echo "Updating sandbox network to: $NETWORK_NAME"
  python3 << PYEOF
import json
try:
    with open("$CONFIG_FILE", "r") as f:
        config = json.load(f)
    if "agents" in config and "defaults" in config["agents"]:
        config["agents"]["defaults"].setdefault("sandbox", {}).setdefault("docker", {})["network"] = "$NETWORK_NAME"
        with open("$CONFIG_FILE", "w") as f:
            json.dump(config, f, indent=2)
    print("✅ Sandbox network synced")
except Exception as e:
    print(f"⚠️ Network sync failed: {e}")
PYEOF
fi

chmod 600 "$CONFIG_FILE"

# -----------------------------------------------------------------------------
# Workspace Seedling & Librarian Setup
# -----------------------------------------------------------------------------
# Sync workspace files (preserves manual edits like 'Laura' name)
if [ -d "/app/workspace-files" ]; then
  echo "Syncing workspace files..."
  cp -un /app/workspace-files/* "$WORKSPACE_DIR/" 2>/dev/null || true
fi

# Ensure Librarian script is present in persistent workspace
if [ -f "/app/scripts/librarian.py" ]; then
  mkdir -p "$WORKSPACE_DIR/scripts"
  cp -u /app/scripts/librarian.py "$WORKSPACE_DIR/scripts/"
fi

# -----------------------------------------------------------------------------
# Recovery & Monitoring (Restored from v1.0)
# -----------------------------------------------------------------------------
if [ -f "/app/scripts/recover_sandbox.sh" ]; then
  echo "Deploying Recovery Protocols..."
  cp -u /app/scripts/recover_sandbox.sh "$WORKSPACE_DIR/"
  cp -u /app/scripts/monitor_sandbox.sh "$WORKSPACE_DIR/"
  chmod +x "$WORKSPACE_DIR/recover_sandbox.sh" "$WORKSPACE_DIR/monitor_sandbox.sh"
  
  # Run initial recovery in background
  nohup bash "$WORKSPACE_DIR/recover_sandbox.sh" > /dev/null 2>&1 &
  # Start background monitor
  nohup bash "$WORKSPACE_DIR/monitor_sandbox.sh" > /dev/null 2>&1 &
fi

# -----------------------------------------------------------------------------
# Post-Startup Task (Background Cron Registration)
# -----------------------------------------------------------------------------
(
  # Wait for gateway to be fully ready
  sleep 15
  if command -v openclaw >/dev/null 2>&1; then
    if ! openclaw cron list | grep -q "librarian"; then
      echo "Registering Librarian cron job..."
      openclaw cron add --name "librarian" \
        --description "Automated knowledge distillation" \
        --every 12h \
        --message "Run python3 /home/node/openclaw-workspace/scripts/librarian.py" \
        --session isolated \
        --model "google-antigravity/gemini-3-flash" \
        --deliver --channel telegram --to "${TELEGRAM_OWNER_ID:-***REMOVED-TELEGRAM-ID***}" || true
    fi
  fi
) &

# -----------------------------------------------------------------------------
# Startup
# -----------------------------------------------------------------------------
ulimit -n 65535
TOKEN=$(grep -o '"token": "[^"]*"' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4)

echo ""
echo "=================================================================="
echo "🦞 OPENCLAW READY"
echo "=================================================================="
echo "Access Token: $TOKEN"
echo "Service URL:  https://${SERVICE_FQDN_OPENCLAW:-localhost}?token=$TOKEN"
echo "=================================================================="
echo ""

exec openclaw gateway run
