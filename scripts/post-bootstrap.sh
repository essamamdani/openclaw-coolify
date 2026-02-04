#!/bin/bash
# Post-Bootstrap Configuration
# This script runs after OpenClaw gateway is up and configures additional features

set -e

echo "🦞 Running Post-Bootstrap Configuration..."

# Wait for gateway to be fully ready
echo "⏳ Waiting for OpenClaw gateway to be ready..."
sleep 10

# Check if gateway is responding
if ! openclaw status &>/dev/null; then
    echo "⚠️  Gateway not ready yet, waiting longer..."
    sleep 20
fi

# 1. Configure Security
echo ""
echo "🔒 Step 1/3: Configuring Exec Security..."
if [ -f /app/scripts/configure-security.sh ]; then
    bash /app/scripts/configure-security.sh
else
    echo "⚠️  Security configuration script not found"
fi

# 2. Install Skills
echo ""
echo "📦 Step 2/3: Installing Essential Skills..."
if [ -f /app/scripts/install-skills.sh ]; then
    bash /app/scripts/install-skills.sh
else
    echo "⚠️  Skills installation script not found"
fi

# 3. Setup Cron Jobs
echo ""
echo "📅 Step 3/3: Setting Up Monitoring Cron Jobs..."
if [ -f /app/scripts/setup-cron-jobs.sh ]; then
    bash /app/scripts/setup-cron-jobs.sh
else
    echo "⚠️  Cron setup script not found"
fi

echo ""
echo "✅ Post-Bootstrap Configuration Complete!"
echo ""
echo "📋 Summary:"
echo "   ✅ Exec security configured (allowlist + approvals)"
echo "   ✅ Essential skills installed (github, weather, summarize, session-logs)"
echo "   ✅ Monitoring cron jobs created (health check, security audit, backup reminder)"
echo ""
echo "⚠️  IMPORTANT: Configure Brave API key for web search:"
echo "   1. Get key from: https://brave.com/search/api/"
echo "   2. Add to Coolify: BRAVE_API_KEY=your-key-here"
echo "   3. Restart deployment"
echo ""
