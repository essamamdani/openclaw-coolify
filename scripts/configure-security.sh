#!/bin/bash
# Configure OpenClaw Exec Security
# This script sets up secure command execution with allowlist

set -e

echo "🦞 Configuring OpenClaw Exec Security..."

CONFIG_FILE="/root/.openclaw/openclaw.json"
BACKUP_FILE="/root/.openclaw/openclaw.json.backup"

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
    echo "📦 Backing up existing config..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create or update config with exec security settings
echo "🔒 Setting up exec security configuration..."

cat > "$CONFIG_FILE" << 'EOF'
{
  "tools": {
    "profile": "coding",
    "exec": {
      "enabled": true,
      "security": "allowlist",
      "ask": true,
      "allowlist": [
        "/usr/bin/git",
        "/usr/bin/docker",
        "/usr/bin/npm",
        "/usr/bin/node",
        "/usr/bin/bun",
        "/usr/local/bin/openclaw",
        "/usr/local/bin/clawhub",
        "/usr/bin/curl",
        "/usr/bin/wget",
        "/usr/bin/ls",
        "/usr/bin/cat",
        "/usr/bin/grep",
        "/usr/bin/find",
        "/usr/bin/df",
        "/usr/bin/free",
        "/usr/bin/top",
        "/usr/bin/ps"
      ],
      "applyPatch": {
        "enabled": false
      },
      "approvals": {
        "enabled": true,
        "timeoutSeconds": 300
      }
    },
    "web": {
      "search": {
        "enabled": true,
        "provider": "brave",
        "count": 10
      },
      "fetch": {
        "enabled": true,
        "maxChars": 50000,
        "timeoutSeconds": 30,
        "readability": true
      }
    },
    "browser": {
      "enabled": true,
      "headless": true,
      "defaultProfile": "openclaw"
    },
    "elevated": {
      "enabled": false
    }
  },
  "skills": {
    "load": {
      "enabled": true,
      "bundled": true,
      "managed": true,
      "workspace": true
    }
  }
}
EOF

echo ""
echo "✅ Exec security configured!"
echo ""
echo "🔒 Security settings:"
echo "   - Exec enabled: YES"
echo "   - Security mode: ALLOWLIST"
echo "   - Ask before exec: YES"
echo "   - Approvals: ENABLED (5 min timeout)"
echo "   - Elevated mode: DISABLED"
echo ""
echo "✅ Allowed commands:"
echo "   - git, docker, npm, node, bun"
echo "   - openclaw, clawhub"
echo "   - curl, wget"
echo "   - ls, cat, grep, find"
echo "   - df, free, top, ps"
echo ""
echo "💡 To add more commands to allowlist, edit: $CONFIG_FILE"
echo "   Then restart the gateway: openclaw gateway restart"
