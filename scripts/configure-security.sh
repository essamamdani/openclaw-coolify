#!/bin/bash
# Configure OpenClaw Web Search (Brave API)
# This script enables web search if BRAVE_API_KEY is set

set -e

echo "🦞 Configuring OpenClaw Web Search..."

# Check if Brave API key is set
if [ -z "$BRAVE_API_KEY" ]; then
    echo "⚠️  BRAVE_API_KEY not set - web search will not be available"
    echo "   Get your API key from: https://brave.com/search/api/"
    echo "   Add it to Coolify environment variables and restart"
    exit 0
fi

echo "✅ BRAVE_API_KEY detected - web search will be enabled"
echo ""
echo "💡 Web search is already configured in the base config"
echo "   Provider: Brave Search"
echo "   Status: Enabled"
echo ""
echo "🔍 Test it by messaging your bot:"
echo "   'Search for latest Docker security best practices'"
