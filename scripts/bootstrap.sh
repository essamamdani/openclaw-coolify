#!/usr/bin/env bash
set -e

STATE_DIR="/home/node/.clawdbot"
CONFIG_FILE="$STATE_DIR/clawdbot.json"
WORKSPACE_DIR="/home/node/clawd"

mkdir -p "$STATE_DIR" "$WORKSPACE_DIR"

# Generate config on first boot
if [ ! -f "$CONFIG_FILE" ]; then
  if command -v openssl >/dev/null 2>&1; then
    TOKEN="$(openssl rand -hex 24)"
  else
    TOKEN="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"
  fi

# Resolve bind address
# The clawdbot JSON config expects a valid IP address for 'bind'.
# We hardcode 0.0.0.0 here so it listens on all interfaces inside the container.
# External binding is controlled by CLAWDBOT_GATEWAY_BIND=lan in docker-compose.yaml.
BIND_ADDR="0.0.0.0"

cat >"$CONFIG_FILE" <<EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$BIND_ADDR",
    "port": 18789,
    "auth": {
      "mode": "token",
      "token": "$TOKEN"
    },
    "tailscale": {
      "mode": "off"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/home/node/clawd"
    }
  }
}
EOF
else
  TOKEN="$(jq -r '.gateway.auth.token' "$CONFIG_FILE")"
fi

# Resolve public URL (Coolify injects SERVICE_URL_CLAWDBOT_18789 or SERVICE_FQDN_CLAWDBOT)
BASE_URL="${SERVICE_URL_CLAWDBOT_18789:-https://$SERVICE_FQDN_CLAWDBOT}"
BASE_URL="${BASE_URL:-http://localhost:18789}"

if [ "${CLAWDBOT_PRINT_ACCESS:-1}" = "1" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🦞 CLAWDBOT READY"
  echo ""
  echo "Dashboard:"
  echo "$BASE_URL/?token=$TOKEN"
  echo ""
  echo "WebSocket:"
  echo "${BASE_URL/https/wss}/__clawdbot__/ws"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

exec node dist/index.js gateway --force