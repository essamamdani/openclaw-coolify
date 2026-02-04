#!/bin/bash
# Update OpenClaw configuration with recommendations

set -e

CONFIG_FILE="/root/.openclaw/openclaw.json"
BACKUP_FILE="/root/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)"

echo "=== OpenClaw Configuration Update ==="
echo "Backing up current config to: $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

echo "Updating configuration..."

# Update workspace access from ro to rw
jq '.agents.defaults.sandbox.workspaceAccess = "rw"' "$CONFIG_FILE" > /tmp/openclaw-updated.json

# Validate the updated config
if jq empty /tmp/openclaw-updated.json 2>/dev/null; then
    echo "✓ Configuration validated successfully"
    mv /tmp/openclaw-updated.json "$CONFIG_FILE"
    echo "✓ Configuration updated"
else
    echo "✗ Configuration validation failed"
    exit 1
fi

echo ""
echo "=== Changes Applied ==="
echo "• Workspace access: ro → rw (allows agent to create/modify files)"
echo ""
echo "=== Next Steps ==="
echo "1. Restart OpenClaw gateway to apply changes"
echo "2. Verify with: openclaw status"
echo ""
echo "To restart: docker restart <container-name>"
