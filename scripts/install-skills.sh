#!/bin/bash
# Install Essential OpenClaw Skills
# This script installs the core skills needed for VPS management

set -e

echo "🦞 Installing Essential OpenClaw Skills..."

# Check if clawhub is available
if ! command -v clawhub &> /dev/null; then
    echo "❌ clawhub not found. Installing..."
    bun install -g clawhub
fi

# Install essential skills
SKILLS=(
    "github"
    "weather"
    "summarize"
    "session-logs"
)

for skill in "${SKILLS[@]}"; do
    echo "📦 Installing skill: $skill"
    if clawhub install "$skill" --yes 2>&1 | grep -q "already installed"; then
        echo "✅ $skill already installed"
    else
        echo "✅ $skill installed successfully"
    fi
done

echo ""
echo "🎉 All essential skills installed!"
echo ""
echo "Installed skills:"
clawhub list

echo ""
echo "💡 Skills will be available in the next agent session."
echo "   Restart the gateway or start a new conversation to load them."
