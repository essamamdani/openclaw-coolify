# OpenClaw Maintenance Schedule

**Last Updated:** February 4, 2026  
**VPS:** netcup  
**Container:** openclaw-qsw0sgsgwcog4wg88g448sgs-*

---

## 📅 Regular Maintenance Tasks

### Monthly Tasks

#### 1. Update OpenClaw Version
**Frequency:** Monthly (or when security patches are released)  
**Last Performed:** February 4, 2026 (v2026.2.2-3)  
**Next Due:** March 4, 2026

**Steps:**
```bash
# 1. Check for updates
ssh netcup "docker exec <container-name> npm view openclaw version"

# 2. Update Dockerfile
# Edit: ARG OPENCLAW_VERSION=<new-version>

# 3. Commit and push
git add Dockerfile
git commit -m "Update OpenClaw to version X.X.X"
git push origin main

# 4. Wait for Coolify rebuild (5-10 minutes)

# 5. Verify
ssh netcup "docker exec <container-name> openclaw --version"
ssh netcup "docker exec <container-name> openclaw status"
```

#### 2. Backup Workspace Data
**Frequency:** Monthly  
**Last Performed:** -  
**Next Due:** March 4, 2026

**Steps:**
```bash
# Create backup
ssh netcup "docker exec <container-name> tar czf /tmp/openclaw-backup-$(date +%Y%m%d).tar.gz /root/openclaw-workspace /root/.openclaw/agents"

# Download backup
ssh netcup "docker cp <container-name>:/tmp/openclaw-backup-$(date +%Y%m%d).tar.gz ./openclaw-backup-$(date +%Y%m%d).tar.gz"

# Store securely (external storage, cloud backup, etc.)
```

**What to Backup:**
- `/root/openclaw-workspace/` - Agent workspace, skills, memory
- `/root/.openclaw/agents/` - Agent configurations and sessions
- `/root/.openclaw/openclaw.json` - Main configuration

---

### Weekly Tasks

#### 1. Review and Clean Sandbox Containers
**Frequency:** Weekly  
**Last Performed:** -  
**Next Due:** February 11, 2026

**Steps:**
```bash
# List all sandboxes
ssh netcup "docker ps -a --filter name=openclaw-sbx"

# Check for stopped sandboxes
ssh netcup "docker ps -a --filter name=openclaw-sbx --filter status=exited"

# Clean up stopped sandboxes
ssh netcup "docker container prune -f --filter label=openclaw.sandbox=true"

# Verify cleanup
ssh netcup "docker ps -a --filter name=openclaw-sbx"
```

#### 2. Review Logs for Errors
**Frequency:** Weekly  
**Last Performed:** -  
**Next Due:** February 11, 2026

**Steps:**
```bash
# Check for errors in last 7 days
ssh netcup "docker logs <container-name> --since 7d | grep -i error"

# Check OpenClaw logs
ssh netcup "docker exec <container-name> openclaw logs --level error --tail 100"

# Review security audit
ssh netcup "docker exec <container-name> openclaw security audit --deep"
```

#### 3. Monitor Resource Usage
**Frequency:** Weekly  
**Last Performed:** -  
**Next Due:** February 11, 2026

**Steps:**
```bash
# Check container stats
ssh netcup "docker stats --no-stream <container-name>"

# Check disk usage
ssh netcup "docker system df"

# Check volume sizes
ssh netcup "docker volume ls -q | xargs docker volume inspect | jq -r '.[] | select(.Name | contains(\"openclaw\")) | .Name + \": \" + .Mountpoint'"
```

---

### Quarterly Tasks

#### 1. Rotate API Keys
**Frequency:** Quarterly  
**Last Performed:** -  
**Next Due:** May 4, 2026

**Steps:**
```bash
# 1. Generate new API keys from providers:
#    - Anthropic: https://console.anthropic.com/
#    - OpenAI: https://platform.openai.com/api-keys
#    - Telegram: @BotFather
#    - Other providers as needed

# 2. Update .env file locally (never commit!)
nano .env

# 3. Update in Coolify dashboard
#    Project → Environment Variables → Update keys

# 4. Restart deployment in Coolify

# 5. Verify channels are working
ssh netcup "docker exec <container-name> openclaw status --deep"
```

#### 2. Review Security Configuration
**Frequency:** Quarterly  
**Last Performed:** February 4, 2026  
**Next Due:** May 4, 2026

**Steps:**
```bash
# Run comprehensive security audit
ssh netcup "docker exec <container-name> openclaw security audit --deep"

# Review configuration
ssh netcup "docker exec <container-name> cat /root/.openclaw/openclaw.json | jq '.gateway, .sandbox, .tools'"

# Check for security updates
# Review: https://docs.openclaw.ai/gateway/security/

# Verify security settings:
# - Sandbox mode: all
# - Workspace access: rw (or ro if appropriate)
# - Elevated tools: disabled
# - Trusted proxies: restricted
# - mDNS mode: off or minimal
```

#### 3. Clean Up Old Sessions
**Frequency:** Quarterly  
**Last Performed:** -  
**Next Due:** May 4, 2026

**Steps:**
```bash
# List sessions
ssh netcup "docker exec <container-name> openclaw sessions list"

# Prune old sessions (older than 90 days)
ssh netcup "docker exec <container-name> openclaw sessions prune --older-than 90d"

# Verify
ssh netcup "docker exec <container-name> openclaw sessions list"
```

---

## 🚨 Emergency Procedures

### Container Won't Start

```bash
# 1. Check logs
ssh netcup "docker logs <container-name>"

# 2. Check environment variables
# Coolify Dashboard → Project → Environment Variables

# 3. Verify configuration
ssh netcup "docker exec <container-name> openclaw config validate"

# 4. Rollback if needed
git revert HEAD
git push origin main
# Wait for Coolify rebuild
```

### High Memory Usage

```bash
# 1. Check memory usage
ssh netcup "docker stats --no-stream <container-name>"

# 2. Check session count
ssh netcup "docker exec <container-name> openclaw sessions list"

# 3. Prune old sessions
ssh netcup "docker exec <container-name> openclaw sessions prune --older-than 7d"

# 4. Restart container if needed
ssh netcup "docker restart <container-name>"
```

### Security Incident

```bash
# 1. Stop the container immediately
ssh netcup "docker stop <container-name>"

# 2. Review logs
ssh netcup "docker logs <container-name> > incident-logs.txt"

# 3. Rotate all credentials
# - Gateway auth token
# - API keys
# - Channel tokens

# 4. Review security audit
ssh netcup "docker exec <container-name> openclaw security audit --deep"

# 5. Update configuration if needed
# 6. Restart with new credentials
```

---

## 📊 Health Check Script

Run this script regularly to check system health:

```bash
#!/bin/bash
# openclaw-health-check.sh

CONTAINER_NAME=$(docker ps --filter name=openclaw --format '{{.Names}}' | head -1)

echo "=== OpenClaw Health Check ==="
echo "Date: $(date)"
echo "Container: $CONTAINER_NAME"
echo ""

# Container status
echo "1. Container Status:"
docker ps --filter name=openclaw --format 'table {{.Names}}\t{{.Status}}\t{{.Size}}'
echo ""

# Resource usage
echo "2. Resource Usage:"
docker stats --no-stream $CONTAINER_NAME
echo ""

# OpenClaw status
echo "3. OpenClaw Status:"
docker exec $CONTAINER_NAME openclaw status
echo ""

# Recent errors
echo "4. Recent Errors (last 24h):"
docker logs $CONTAINER_NAME --since 24h 2>&1 | grep -i error | tail -10
echo ""

# Sandbox count
echo "5. Sandbox Containers:"
docker ps -a --filter name=openclaw-sbx --format 'table {{.Names}}\t{{.Status}}'
echo ""

# Security audit
echo "6. Security Audit:"
docker exec $CONTAINER_NAME openclaw security audit --deep
echo ""

echo "=== Health Check Complete ==="
```

**Deploy to VPS:**
```bash
scp openclaw-health-check.sh netcup:/root/openclaw-health-check.sh
ssh netcup "chmod +x /root/openclaw-health-check.sh"
```

**Run:**
```bash
ssh netcup "sudo /root/openclaw-health-check.sh"
```

---

## 📝 Change Log

### 2026-02-04
- ✅ Initial configuration verified against official docs
- ✅ Workspace access updated: `ro` → `rw`
- ✅ Security audit passed (0 critical, 0 warn, 1 info)
- ✅ All recommendations implemented
- ✅ Maintenance schedule created

---

## 🔗 Quick Reference

**Container Name Pattern:**
```
openclaw-qsw0sgsgwcog4wg88g448sgs-<timestamp>
```

**Get Current Container:**
```bash
ssh netcup "docker ps --filter name=openclaw --format '{{.Names}}' | head -1"
```

**Essential Commands:**
```bash
# Status
ssh netcup "docker exec <container-name> openclaw status"

# Health
ssh netcup "docker exec <container-name> openclaw health"

# Security audit
ssh netcup "docker exec <container-name> openclaw security audit --deep"

# Logs
ssh netcup "docker logs -f <container-name>"

# Restart
ssh netcup "docker restart <container-name>"
```

**Dashboard URL:**
```
https://bot.appautomation.cloud?token=xK7mR9pL2nQ4wF6jH8vB3cT5yG1dN0sA
```

**Telegram Bot:**
```
@meinopenclawbot
```

---

## 📚 Resources

- **Official Docs:** https://docs.openclaw.ai/
- **Security Guide:** https://docs.openclaw.ai/gateway/security/
- **Troubleshooting:** https://docs.openclaw.ai/troubleshooting
- **GitHub Issues:** https://github.com/openclaw/openclaw/issues
- **This Repo:** https://github.com/amraly83/openclaw-coolify

---

**Next Scheduled Maintenance:** February 11, 2026 (Weekly tasks)
