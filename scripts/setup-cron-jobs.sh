#!/bin/bash
# Setup OpenClaw Monitoring Cron Jobs
# Note: Cron jobs should be created via Telegram bot or dashboard
# The CLI syntax for cron jobs has changed in OpenClaw 2026.2.2-3

set -e

echo "🦞 OpenClaw Monitoring Cron Jobs Setup"
echo ""
echo "⚠️  Note: Cron jobs are best created via Telegram bot or dashboard"
echo ""
echo "📋 Recommended cron jobs to create:"
echo ""
echo "1️⃣  Daily Health Check (2 AM)"
echo "   Message your bot on Telegram:"
echo "   'Create a cron job that runs daily at 2 AM to check system health"
echo "   (container status, memory usage, errors, sandbox count)."
echo "   Report only if issues found.'"
echo ""
echo "2️⃣  Weekly Security Audit (Sunday 3 AM)"
echo "   Message your bot on Telegram:"
echo "   'Create a cron job that runs every Sunday at 3 AM to run"
echo "   openclaw security audit --deep and report findings."
echo "   Report only if critical or warning issues found.'"
echo ""
echo "3️⃣  Daily Backup Reminder (3 AM)"
echo "   Message your bot on Telegram:"
echo "   'Create a cron job that runs daily at 3 AM to check if"
echo "   workspace backup exists from today. Remind if not backed up.'"
echo ""
echo "💡 After creating jobs, verify with:"
echo "   openclaw cron list"
echo ""
echo "✅ Cron setup instructions displayed"
