#!/usr/bin/env bash
set -e

OPENCLAW_STATE="/root/.openclaw"
CONFIG_FILE="$OPENCLAW_STATE/openclaw.json"
WORKSPACE_DIR="/root/openclaw-workspace"



mkdir -p "$OPENCLAW_STATE" "$WORKSPACE_DIR"
chmod 700 "$OPENCLAW_STATE"

mkdir -p "$OPENCLAW_STATE/credentials"
mkdir -p "$OPENCLAW_STATE/agents/main/sessions"
chmod 700 "$OPENCLAW_STATE/credentials"

# ----------------------------
# gog CLI: Symlink config to persistent storage
# ----------------------------
mkdir -p "$OPENCLAW_STATE/gogcli"
if [ ! -L "/root/.config/gogcli" ]; then
  mkdir -p /root/.config
  ln -sf "$OPENCLAW_STATE/gogcli" /root/.config/gogcli
fi

# ----------------------------
# Security: Ensure config file permissions on every startup
# ----------------------------
if [ -f "$CONFIG_FILE" ]; then
  chmod 600 "$CONFIG_FILE"
fi

# ----------------------------
# Seed Agent Workspaces
# ----------------------------
seed_agent() {
  local id="$1"
  local name="$2"
  local dir="/root/openclaw-$id"

  if [ "$id" = "main" ]; then
    dir="/root/openclaw-workspace"
  fi

  mkdir -p "$dir"

  # NEVER overwrite existing SOUL.md
  if [ -f "$dir/SOUL.md" ]; then
    echo "SOUL.md already exists for $id - skipping"
    return 0
  fi

  # MAIN agent gets ORIGINAL repo SOUL.md and BOOTSTRAP.md
  if [ "$id" = "main" ]; then
    if [ -f "./SOUL.md" ] && [ ! -f "$dir/SOUL.md" ]; then
      echo "Copying original SOUL.md to $dir"
      cp "./SOUL.md" "$dir/SOUL.md"
    fi
    if [ -f "./BOOTSTRAP.md" ] && [ ! -f "$dir/BOOTSTRAP.md" ]; then
      echo "Seeding BOOTSTRAP.md to $dir"
      cp "./BOOTSTRAP.md" "$dir/BOOTSTRAP.md"
    fi
    return 0
  fi

  # fallback for other agents
  cat >"$dir/SOUL.md" <<EOF
# SOUL.md - $name
You are OpenClaw, a helpful and premium AI assistant.
EOF
}

seed_agent "main" "OpenClaw"

# ----------------------------
# Generate Config with Prime Directive
# ----------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Generating openclaw.json with task-based model assignment..."
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
    },
    "load": {
      "watch": true,
      "watchDebounceMs": 1000
    }
  },
  "gateway": {
  "port": $OPENCLAW_GATEWAY_PORT,
  "mode": "local",
    "bind": "loopback",
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": false
    },
    "trustedProxies": [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ],
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    },
    "auth": { "mode": "token", "token": "$TOKEN" },
    "reload": { "mode": "hybrid" }
  },
  "agents": {
    "defaults": {
      "workspace": "$WORKSPACE_DIR",
      "envelopeTimestamp": "on",
      "envelopeElapsed": "on",
      "elevatedDefault": "full",
      "cliBackends": {},
      "model": {
        "primary": "google-antigravity/claude-opus-4-5-thinking",
        "fallbacks": [
          "google-antigravity/gemini-3-flash",
          "mistral/mistral-large-latest",
          "mistral/codestral-latest"
        ]
      },
      "models": {
        "google-antigravity/claude-opus-4-5-thinking": { "alias": "opus" },
        "google-antigravity/gemini-3-flash": { "alias": "flash" },
        "mistral/mistral-large-latest": { "alias": "mistral" },
        "mistral/codestral-latest": { "alias": "codestral" }
      },
      "heartbeat": {
        "every": "30m",
        "model": "google-antigravity/gemini-3-flash",
        "target": "last"
      },
      "subagents": {
        "model": "google-antigravity/gemini-3-flash",
        "maxConcurrent": 4,
        "archiveAfterMinutes": 60
      },
      "imageModel": {
        "primary": "google-antigravity/gemini-3-flash",
        "fallbacks": ["google-antigravity/claude-opus-4-5-thinking"]
      },
      "contextTokens": 200000,
      "maxConcurrent": 4,
      "sandbox": {
        "mode": "all",
        "workspaceAccess": "rw",
        "scope": "session",
        "docker": {
          "readOnlyRoot": true,
          "network": "DYNAMIC_NETWORK_PLACEHOLDER",
          "capDrop": ["ALL"],
          "pidsLimit": 256,
          "memory": "1g",
          "memorySwap": "2g",
          "cpus": 1,
          "user": "1000:1000",
          "tmpfs": ["/tmp", "/var/tmp", "/run"]
        },
        "prune": {
          "idleHours": 24,
          "maxAgeDays": 7
        }
      }
    },
    "list": [
      { "id": "main", "default": true, "name": "default", "workspace": "/root/openclaw-workspace" }
    ]
  },
  "messages": {
    "queue": {
      "mode": "collect",
      "debounceMs": 2000,
      "cap": 20
    },
    "inbound": {
      "debounceMs": 2000
    }
  },
  "tools": {
    "elevated": {
      "enabled": false
    },
    "web": {
      "search": {
        "enabled": true,
        "provider": "brave"
      },
      "fetch": {
        "enabled": true
      }
    }
  },
  "logging": {
    "redactSensitive": "tools"
  },
  "discovery": {
    "mdns": {
      "mode": "off"
    }
  },
  "session": {
    "dmScope": "per-channel-peer"
  },
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "groupAllowFrom": [],
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    },
    "telegram": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "groupAllowFrom": [],
      "streamMode": "partial",
      "capabilities": {
        "inlineButtons": "all"
      },
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  }
}
EOF
fi

# ----------------------------
# Fix dynamic sandbox network (if config exists)
# ----------------------------
if [ -f "$CONFIG_FILE" ]; then
  # Detect the actual openclaw-internal network name
  NETWORK_NAME=$(docker network ls --filter name=openclaw-internal --format "{{.Name}}" 2>/dev/null | head -1)
  
  if [ -n "$NETWORK_NAME" ]; then
    # Check if config has placeholder or wrong network
    CURRENT_NETWORK=$(grep -o '"network": "[^"]*"' "$CONFIG_FILE" | grep -o 'openclaw-internal' || echo "")
    
    if [ -z "$CURRENT_NETWORK" ] || grep -q "DYNAMIC_NETWORK_PLACEHOLDER" "$CONFIG_FILE"; then
      echo "Updating sandbox network to: $NETWORK_NAME"
      python3 << PYEOF
import json
try:
    with open("$CONFIG_FILE", "r") as f:
        config = json.load(f)
    
    if "agents" in config and "defaults" in config["agents"]:
        if "sandbox" in config["agents"]["defaults"]:
            if "docker" in config["agents"]["defaults"]["sandbox"]:
                config["agents"]["defaults"]["sandbox"]["docker"]["network"] = "$NETWORK_NAME"
                
                with open("$CONFIG_FILE", "w") as f:
                    json.dump(config, f, indent=2)
                print(f"✅ Sandbox network updated to: $NETWORK_NAME")
except Exception as e:
    print(f"⚠️ Could not update network: {e}")
PYEOF
    fi
  fi
fi

# ----------------------------
# Export state
# ----------------------------
export OPENCLAW_STATE_DIR="$OPENCLAW_STATE"

# ----------------------------
# Copy repository skills to workspace
# ----------------------------
if [ -d "./skills" ]; then
  echo "Copying repository skills to workspace..."
  mkdir -p "$WORKSPACE_DIR/skills"
  cp -r ./skills/* "$WORKSPACE_DIR/skills/" 2>/dev/null || true
  echo "Skills copied: $(ls -1 $WORKSPACE_DIR/skills/ 2>/dev/null | tr '\n' ' ')"
fi

# ----------------------------
# Copy workspace files (guides, templates)
# ----------------------------
if [ -d "./workspace-files" ]; then
  echo "Copying workspace files..."
  cp -r ./workspace-files/* "$WORKSPACE_DIR/" 2>/dev/null || true
fi

# ----------------------------
# Sandbox setup
# ----------------------------
[ -f scripts/sandbox-setup.sh ] && bash scripts/sandbox-setup.sh
[ -f scripts/sandbox-browser-setup.sh ] && bash scripts/sandbox-browser-setup.sh

# ----------------------------
# Recovery & Monitoring
# ----------------------------
if [ -f scripts/recover_sandbox.sh ]; then
  echo "Deploying Recovery Protocols..."
  cp scripts/recover_sandbox.sh "$WORKSPACE_DIR/"
  cp scripts/monitor_sandbox.sh "$WORKSPACE_DIR/"
  chmod +x "$WORKSPACE_DIR/recover_sandbox.sh" "$WORKSPACE_DIR/monitor_sandbox.sh"
  
  # Run initial recovery
  bash "$WORKSPACE_DIR/recover_sandbox.sh"
  
  # Start background monitor
  nohup bash "$WORKSPACE_DIR/monitor_sandbox.sh" >/dev/null 2>&1 &
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
    SAVED_TOKEN=$(grep -o '"token": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    if [ -n "$SAVED_TOKEN" ]; then
        TOKEN="$SAVED_TOKEN"
    fi
fi

echo ""
echo "=================================================================="
echo "OpenClaw is ready!"
echo "=================================================================="
echo ""
echo "Access Token: $TOKEN"
echo ""
echo "Service URL (Local): http://localhost:${OPENCLAW_GATEWAY_PORT:-18789}?token=$TOKEN"
if [ -n "$SERVICE_FQDN_OPENCLAW" ]; then
    echo "Service URL (Public): https://${SERVICE_FQDN_OPENCLAW}?token=$TOKEN"
    echo "    (Wait for cloud tunnel to propagate if just started)"
fi
echo ""
echo "Onboarding:"
echo "   1. Access the UI using the link above."
echo "   2. To approve this machine, run inside the container:"
echo "      openclaw-approve"
echo "   3. To start the onboarding wizard:"
echo "      openclaw onboard"
echo ""
echo "=================================================================="
echo "Current ulimit is: $(ulimit -n)"
exec openclaw gateway run
