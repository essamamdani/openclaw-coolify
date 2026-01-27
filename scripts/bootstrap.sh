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


cat >"$CONFIG_FILE" <<EOF
{
  "meta": {
    "lastTouchedVersion": "2026.1.25",
    "lastTouchedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "wizard": {
    "lastRunMode": "local",
    "lastRunAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "lastRunVersion": "2026.1.25",
    "lastRunCommand": "doctor"
  },
  "diagnostics": {
    "otel": {
      "enabled": true
    }
  },
  "update": {
    "channel": "stable"
  },
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "mediaMaxMb": 50,
      "debounceMs": 0
    },
    "telegram": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    },
    "discord": {
      "dm": {
        "policy": "pairing"
      },
      "groupPolicy": "allowlist"
    },
    "googlechat": {
      "dm": {
        "policy": "pairing"
      },
      "groupPolicy": "allowlist"
    },
    "slack": {
      "mode": "socket",
      "webhookPath": "/slack/events",
      "userTokenReadOnly": true,
      "dm": {
        "policy": "pairing"
      },
      "groupPolicy": "allowlist"
    },
    "signal": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    },
    "imessage": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    },
    "mattermost": {
      "dmPolicy": "pairing"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/home/node/clawd",
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    }
  },
  "tools": {
    "agentToAgent": {
      "allow": []
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "hooks": {
    "enabled": true,
    "token": "$TOKEN",
    "internal": {
      "enabled": true,
      "entries": {
        "boot-md": {
          "enabled": true
        },
        "command-logger": {
          "enabled": true
        },
        "session-memory": {
          "enabled": true
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "auto",
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": false
    },
    "auth": {
      "mode": "token",
      "token": "$TOKEN"
    },
    "trustedProxies": [
      "*"
    ],
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "skills": {
    "allowBundled": [],
    "install": {
      "nodeManager": "npm"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      },
      "whatsapp": {
        "enabled": true
      },
      "discord": {
        "enabled": true
      },
      "googlechat": {
        "enabled": true
      },
      "slack": {
        "enabled": true
      },
      "signal": {
        "enabled": true
      },
      "imessage": {
        "enabled": true
      }
    }
  }
}
EOF
else
  TOKEN="$(jq -r '.gateway.auth.token' "$CONFIG_FILE")"
fi

# Resolve public URL (Coolify injects SERVICE_URL_CLAWDBOT_18789 or SERVICE_FQDN_CLAWDBOT)
BASE_URL="${SERVICE_URL_CLAWDBOT_18789:-${SERVICE_FQDN_CLAWDBOT:+https://$SERVICE_FQDN_CLAWDBOT}}"
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

exec node dist/index.js gateway