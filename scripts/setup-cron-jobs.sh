#!/bin/bash
# Setup OpenClaw Monitoring Cron Jobs
# This script creates automated health checks and security audits

set -e

echo "🦞 Setting up OpenClaw Monitoring Cron Jobs..."

# Daily health check at 2 AM
echo "📅 Creating daily health check job..."
openclaw cron add \
  --name "daily-health-check" \
  --schedule "0 2 * * *" \
  --message "Run health check: Check container status, memory usage (report if >80%), recent errors in logs, and sandbox count. If everything is OK, just say 'Health check passed ✅'. If issues found, report them with details." \
  2>&1 || echo "⚠️  Health check job may already exist"

# Weekly security audit on Sundays at 3 AM
echo "🔒 Creating weekly security audit job..."
openclaw cron add \
  --name "weekly-security-audit" \
  --schedule "0 3 * * 0" \
  --message "Run 'openclaw security audit --deep' and report findings. If no critical or warning issues, just say 'Security audit passed ✅'. If issues found, report them with recommended actions." \
  2>&1 || echo "⚠️  Security audit job may already exist"

# Daily backup reminder at 3 AM
echo "💾 Creating daily backup reminder..."
openclaw cron add \
  --name "daily-backup-reminder" \
  --schedule "0 3 * * *" \
  --message "Check if workspace backup exists from today. If not, remind to run backup. Workspace is at /root/openclaw-workspace and should be backed up regularly." \
  2>&1 || echo "⚠️  Backup reminder job may already exist"

echo ""
echo "🎉 Cron jobs configured successfully!"
echo ""
echo "📋 Current cron jobs:"
openclaw cron list

echo ""
echo "💡 Tips:"
echo "   - View cron history: openclaw cron runs"
echo "   - Test a job now: openclaw cron run --name daily-health-check"
echo "   - Remove a job: openclaw cron rm --name <job-name>"
