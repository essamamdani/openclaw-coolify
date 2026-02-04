#!/bin/bash
# Install Essential OpenClaw Skills
# This script installs skills from ClawHub and copies them to workspace

set -e

echo "🦞 Installing Essential OpenClaw Skills..."

# Create workspace skills directory
echo "📁 Creating workspace skills directory..."
mkdir -p /root/openclaw-workspace/skills

# Install skills using clawhub (they go to sandbox)
echo "📦 Installing github skill..."
clawhub install github --yes 2>&1 || echo "⚠️  github skill may already be installed"

echo "📦 Installing weather skill..."
clawhub install weather --yes 2>&1 || echo "⚠️  weather skill may already be installed"

echo "📦 Installing summarize skill..."
clawhub install summarize --yes 2>&1 || echo "⚠️  summarize skill may already be installed"

echo "📦 Installing session-logs skill..."
clawhub install session-logs --yes 2>&1 || echo "⚠️  session-logs skill may already be installed"

# Wait a moment for skills to be installed
sleep 2

# Find and copy skills from sandbox to workspace
echo ""
echo "📋 Copying skills to workspace..."

# Find the most recent sandbox with skills
SANDBOX_DIR=$(find /root/.openclaw/sandboxes -name "skills" -type d 2>/dev/null | head -1)

if [ -n "$SANDBOX_DIR" ]; then
    echo "📂 Found skills in: $SANDBOX_DIR"
    
    # Copy each skill if it exists
    for skill in github weather summarize session-logs; do
        if [ -d "$SANDBOX_DIR/$skill" ]; then
            echo "   Copying $skill..."
            cp -r "$SANDBOX_DIR/$skill" /root/openclaw-workspace/skills/ 2>/dev/null || true
        fi
    done
    
    echo "✅ Skills copied to workspace"
else
    echo "⚠️  No sandbox skills directory found yet"
    echo "   Skills will be available after first agent run"
fi

echo ""
echo "✅ Skills installation complete!"
echo ""
echo "📋 Installed skills:"
echo "   - github: GitHub CLI integration"
echo "   - weather: Weather forecasts"
echo "   - summarize: Content summarization"
echo "   - session-logs: Conversation search"
echo ""
echo "💡 Skills location: /root/openclaw-workspace/skills/"
echo "💡 Restart gateway to load: openclaw gateway restart"
