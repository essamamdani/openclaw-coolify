#!/bin/bash
# Post-Bootstrap Setup Script
# Runs after OpenClaw bootstrap to configure features

set -e

echo "🦞 Running Post-Bootstrap Setup..."
echo ""

# Wait for gateway to be fully ready
echo "⏳ Waiting for gateway to be ready..."
sleep 10

# Check if gateway is running
if ! openclaw status > /dev/null 2>&1; then
    echo "⚠️  Gateway not ready yet, skipping post-bootstrap setup"
    echo "   Setup scripts can be run manually later"
    exit 0
fi

echo "✅ Gateway is ready"
echo ""

# Check web search configuration
echo "1️⃣  Checking web search configuration..."
bash /app/scripts/configure-security.sh
echo ""

# Install skills
echo "2️⃣  Installing skills..."
bash /app/scripts/install-skills.sh
echo ""

# Display cron job instructions
echo "3️⃣  Cron job setup instructions..."
bash /app/scripts/setup-cron-jobs.sh
echo ""

# Restart gateway to load skills
echo "4️⃣  Restarting gateway to load skills..."
openclaw gateway restart 2>&1 || echo "⚠️  Gateway restart will happen automatically"
echo ""

echo "🎉 Post-bootstrap setup complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Add BRAVE_API_KEY to Coolify (if not already set)"
echo "   2. Create cron jobs via Telegram bot (see instructions above)"
echo "   3. Test features: web search, skills, browser automation"
