#!/bin/bash
# Fix Skills Location
# This script copies skills from sandbox to workspace
# Run this on the current container to fix skills immediately

set -e

echo "🦞 Fixing Skills Location..."
echo ""

# Create workspace skills directory
echo "📁 Creating workspace skills directory..."
mkdir -p /root/openclaw-workspace/skills

# Find sandbox with skills
echo "🔍 Finding installed skills..."
SANDBOX_DIR=$(find /root/.openclaw/sandboxes -name "skills" -type d 2>/dev/null | head -1)

if [ -z "$SANDBOX_DIR" ]; then
    echo "❌ No sandbox skills directory found"
    echo "   Skills need to be installed first"
    exit 1
fi

echo "📂 Found skills in: $SANDBOX_DIR"
echo ""

# Copy each skill
SKILLS_COPIED=0
for skill in github weather summarize session-logs; do
    if [ -d "$SANDBOX_DIR/$skill" ]; then
        echo "📦 Copying $skill..."
        cp -r "$SANDBOX_DIR/$skill" /root/openclaw-workspace/skills/
        SKILLS_COPIED=$((SKILLS_COPIED + 1))
    else
        echo "⚠️  $skill not found in sandbox"
    fi
done

echo ""
if [ $SKILLS_COPIED -gt 0 ]; then
    echo "✅ Copied $SKILLS_COPIED skills to workspace"
    echo ""
    echo "📋 Skills in workspace:"
    ls -la /root/openclaw-workspace/skills/
    echo ""
    echo "🔄 Restarting gateway to load skills..."
    openclaw gateway restart
    echo ""
    echo "✅ Done! Skills should now be available"
    echo ""
    echo "💡 Verify with: openclaw skills list"
else
    echo "❌ No skills were copied"
    echo "   Make sure skills are installed first"
fi
