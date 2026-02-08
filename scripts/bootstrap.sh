#!/usr/bin/env bash
set -e

if [ -f "/app/scripts/migrate-to-data.sh" ]; then
    bash "/app/scripts/migrate-to-data.sh"
fi

OPENCLAW_STATE="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
CONFIG_FILE="$OPENCLAW_STATE/openclaw.json"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE:-/data/openclaw-workspace}"

mkdir -p "$OPENCLAW_STATE" "$WORKSPACE_DIR"
chmod 700 "$OPENCLAW_STATE"

mkdir -p "$OPENCLAW_STATE/credentials"
mkdir -p "$OPENCLAW_STATE/agents/main/sessions"
mkdir -p "$OPENCLAW_STATE/agents/jarvis/sessions"
mkdir -p "$OPENCLAW_STATE/agents/developer/sessions"
chmod 700 "$OPENCLAW_STATE/credentials"

for dir in .agents .ssh .config .local .cache .npm .bun .claude .kimi; do
    if [ ! -L "/root/$dir" ] && [ ! -e "/root/$dir" ]; then
        ln -sf "/data/$dir" "/root/$dir"
    fi
done

# ----------------------------
# Seed Agent Workspaces
# ----------------------------
seed_agent() {
  local id="$1"
  local name="$2"
  local dir="/data/openclaw-$id"

  if [ "$id" = "main" ]; then
    dir="${OPENCLAW_WORKSPACE:-/data/openclaw-workspace}"
  fi

  mkdir -p "$dir"

  # 🔒 NEVER overwrite existing SOUL.md
  if [ -f "$dir/SOUL.md" ]; then
    echo "🧠 SOUL.md already exists for $id — skipping"
    return 0
  fi

  # ✅ MAIN agent gets ORIGINAL repo SOUL.md and BOOTSTRAP.md
  if [ "$id" = "main" ]; then
    if [ -f "./SOUL.md" ] && [ ! -f "$dir/SOUL.md" ]; then
      echo "✨ Copying original SOUL.md to $dir"
      cp "./SOUL.md" "$dir/SOUL.md"
    fi
    if [ -f "./BOOTSTRAP.md" ] && [ ! -f "$dir/BOOTSTRAP.md" ]; then
      echo "🚀 Seeding BOOTSTRAP.md to $dir"
      cp "./BOOTSTRAP.md" "$dir/BOOTSTRAP.md"
    fi
    return 0
  fi

  # Secondary agents: copy from agents/ directory if available
  if [ -d "/app/agents/$id" ]; then
    for f in SOUL.md HEARTBEAT.md AGENTS.md; do
      if [ -f "/app/agents/$id/$f" ] && [ ! -f "$dir/$f" ]; then
        echo "Seeding $f for agent $id"
        cp "/app/agents/$id/$f" "$dir/$f"
      fi
    done
    mkdir -p "$dir/memory"
    return 0
  fi

  # Final fallback for other agents
  cat >"$dir/SOUL.md" <<EOF
# SOUL.md - $name
You are OpenClaw, a helpful and premium AI assistant.
EOF
  mkdir -p "$dir/memory"
}

seed_agent "main" "OpenClaw"
seed_agent "jarvis" "Jarvis"
seed_agent "developer" "Developer"

# ----------------------------
# Generate Config with Prime Directive
# ----------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🏥 Generating openclaw.json with Prime Directive..."
  TOKEN=$(openssl rand -hex 24 2>/dev/null || node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")
  cat >"$CONFIG_FILE" <<EOF
{
"commands": {
    "native": true,
    "nativeSkills": true,
    "text": true,
    "bash": true,
    "config": true,
    "debug": true,
    "restart": true,
    "useAccessGroups": true
  },
  "plugins": {
    "enabled": true,
    "entries": {
      "whatsapp": {
        "enabled": true
      },
      "telegram": {
        "enabled": true
      },
      "google-antigravity-auth": {
        "enabled": true
      }
    }
  },
  "skills": {
    "allowBundled": [
      "*"
    ],
    "install": {
      "nodeManager": "npm"
    }
  },
  "gateway": {
  "port": $OPENCLAW_GATEWAY_PORT,
  "mode": "local",
    "bind": "lan",
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": false
    },
    "trustedProxies": [
      "*"
    ],
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    },
    "auth": { "mode": "token", "token": "$TOKEN" }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "moonshot": {
        "baseUrl": "https://api.moonshot.ai/v1",
        "apiKey": "\${KIMI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "kimi-k2.5",
            "name": "Kimi K2.5",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 256000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "moonshot/kimi-k2.5" },
      "workspace": "$WORKSPACE_DIR",
      "envelopeTimestamp": "on",
      "envelopeElapsed": "on",
      "cliBackends": {},
      "heartbeat": {
        "every": "1h"
      },
      "maxConcurrent": 4,
      "sandbox": {
        "mode": "non-main",
        "scope": "session",
        "browser": {
          "enabled": true
        }
      }
    },
    "list": [
      { "id": "main", "default": true, "name": "default", "workspace": "${OPENCLAW_WORKSPACE:-/data/openclaw-workspace}" },
      {
        "id": "jarvis",
        "name": "Jarvis",
        "workspace": "/data/openclaw-jarvis",
        "heartbeat": { "every": "15m" }
      },
      {
        "id": "developer",
        "name": "Developer",
        "workspace": "/data/openclaw-developer",
        "heartbeat": { "every": "15m" }
      }
    ]
  }
}
EOF
fi

# ----------------------------
# Export state
# ----------------------------
export OPENCLAW_STATE_DIR="$OPENCLAW_STATE"

# ----------------------------
# Sandbox setup
# ----------------------------
[ -f scripts/sandbox-setup.sh ] && bash scripts/sandbox-setup.sh
[ -f scripts/sandbox-browser-setup.sh ] && bash scripts/sandbox-browser-setup.sh

# ----------------------------
# Recovery & Monitoring
# ----------------------------
if [ -f scripts/recover_sandbox.sh ]; then
  echo "🛡️  Deploying Recovery Protocols..."
  cp scripts/recover_sandbox.sh "$WORKSPACE_DIR/"
  cp scripts/monitor_sandbox.sh "$WORKSPACE_DIR/"
  chmod +x "$WORKSPACE_DIR/recover_sandbox.sh" "$WORKSPACE_DIR/monitor_sandbox.sh"
  
  # Run initial recovery
  bash "$WORKSPACE_DIR/recover_sandbox.sh"
  
  # Start background monitor
  nohup bash "$WORKSPACE_DIR/monitor_sandbox.sh" >/dev/null 2>&1 &
fi

# ----------------------------
# Mission Control Setup
# ----------------------------

# Write shared config for Mission Control UI (always, even without Convex)
MC_SHARED_DIR="/mc-shared"
mkdir -p "$MC_SHARED_DIR"

# Extract token for mc-config.json
MC_TOKEN=""
if [ -f "$CONFIG_FILE" ]; then
  MC_TOKEN=$(jq -r '.gateway.auth.token // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

# Build agent list from config
MC_AGENTS='["jarvis","developer"]'
if [ -f "$CONFIG_FILE" ]; then
  MC_AGENTS=$(jq -c '[.agents.list[]? | .id] // ["jarvis","developer"]' "$CONFIG_FILE" 2>/dev/null || echo '["jarvis","developer"]')
fi

cat >"$MC_SHARED_DIR/mc-config.json" <<MCEOF
{
  "gatewayToken": "$MC_TOKEN",
  "gatewayPort": ${OPENCLAW_GATEWAY_PORT:-18789},
  "gatewayUrl": "https://${SERVICE_FQDN_OPENCLAW:-localhost:${OPENCLAW_GATEWAY_PORT:-18789}}",
  "gatewayLocalUrl": "http://openclaw:${OPENCLAW_GATEWAY_PORT:-18789}",
  "agents": $MC_AGENTS,
  "model": "moonshot/kimi-k2.5",
  "convexEnabled": $([ -n "${CONVEX_URL:-}" ] && echo "true" || echo "false")
}
MCEOF
echo "Mission Control config written to $MC_SHARED_DIR/mc-config.json"

# Start Mission Control sidecar API (agent management) with auto-restart
if [ -f scripts/mc-sidecar.js ]; then
  echo "Starting Mission Control sidecar API on port 18790..."
  (
    while true; do
      MC_SHARED_DIR="$MC_SHARED_DIR" \
      OPENCLAW_CONFIG_FILE="$CONFIG_FILE" \
      OPENCLAW_STATE_DIR="$OPENCLAW_STATE" \
      node scripts/mc-sidecar.js 2>&1 || true
      echo "[mc-sidecar] Crashed, restarting in 3s..."
      sleep 3
    done
  ) &
fi

# Convex integration (optional)
if [ -n "${CONVEX_URL:-}" ]; then
  # One-time Convex initialization
  if [ -f scripts/convex-setup.sh ]; then
    bash scripts/convex-setup.sh || echo "Convex setup encountered an issue (non-fatal)"
  fi

  # Start notification daemon
  if [ -f scripts/notification-daemon.sh ]; then
    echo "Starting Mission Control notification daemon..."
    chmod +x scripts/notification-daemon.sh
    nohup bash scripts/notification-daemon.sh >/dev/null 2>&1 &
  fi
fi

# ----------------------------
# Run OpenClaw
# ----------------------------
ulimit -n 65535
# ----------------------------
# Banner & Access Info
# ----------------------------
# Try to extract existing token if not already set (e.g. from previous run)
if [ -f "$CONFIG_FILE" ]; then
    SAVED_TOKEN=$(jq -r '.gateway.auth.token // empty' "$CONFIG_FILE" 2>/dev/null || grep -o '"token": "[^"]*"' "$CONFIG_FILE" | tail -1 | cut -d'"' -f4)
    if [ -n "$SAVED_TOKEN" ]; then
        TOKEN="$SAVED_TOKEN"
    fi
fi

echo ""
echo "=================================================================="
echo "🦞 OpenClaw is ready!"
echo "=================================================================="
echo ""
echo "🔑 Access Token: $TOKEN"
echo ""
echo "🌍 Service URL (Local): http://localhost:${OPENCLAW_GATEWAY_PORT:-18789}?token=$TOKEN"
if [ -n "$SERVICE_FQDN_OPENCLAW" ]; then
    echo "☁️  Service URL (Public): https://${SERVICE_FQDN_OPENCLAW}?token=$TOKEN"
    echo "    (Wait for cloud tunnel to propagate if just started)"
fi
echo ""
echo "👉 Onboarding:"
echo "   1. Access the UI using the link above."
echo "   2. To approve this machine, run inside the container:"
echo "      openclaw-approve"
echo "   3. To start the onboarding wizard:"
echo "      openclaw onboard"
echo ""
echo "=================================================================="
echo "🔧 Current ulimit is: $(ulimit -n)"
exec openclaw gateway run