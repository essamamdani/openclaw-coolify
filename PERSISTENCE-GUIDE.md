# 🔒 OpenClaw Persistence Guide

## What Survives Container Recreation?

This guide explains what's permanent and what's temporary in your OpenClaw deployment.

---

## ✅ PERMANENT (Survives Everything)

### 1. Git Repository Changes
**Location:** GitHub repository  
**Survives:** Container recreation, image updates, server reboots

**What's included:**
- ✅ `Dockerfile` (Playwright installation)
- ✅ `docker-compose.yaml` (security configuration)
- ✅ All scripts in `scripts/` directory
- ✅ Documentation (AGENTS.md, TOOLS-ANALYSIS.md, etc.)
- ✅ Skills in `skills/` directory (if you add custom ones)

**Why permanent:** Coolify rebuilds from GitHub on every deployment. These changes are baked into the Docker image.

**Verification:**
```bash
# Check what's in the image
ssh ***REMOVED-VPS*** "docker exec <container> ls -la /app/scripts/"
```

---

### 2. Docker Volumes (Persistent Data)
**Location:** Docker volumes on VPS host  
**Survives:** Container recreation, image updates (but NOT if volumes are deleted)

#### Volume 1: `openclaw-workspace`
**Mount:** `/root/openclaw-workspace`  
**Contains:**
- ✅ **Skills** (`/root/openclaw-workspace/skills/`)
- ✅ Agent workspace files
- ✅ Memory files (`memory/YYYY-MM-DD.md`)
- ✅ Session data
- ✅ Conversation history

**Verified persistent:**
```bash
# Skills survived container recreation
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-103249061467 ls -la /root/openclaw-workspace/skills/"
# Output: github, session-logs, summarize, weather ✅
```

#### Volume 2: `openclaw-config`
**Mount:** `/root/.openclaw`  
**Contains:**
- ✅ Agent configuration (`openclaw.json`)
- ✅ OAuth credentials
- ✅ Cron jobs (when created)
- ✅ Session state
- ✅ Auth profiles

**Why permanent:** Docker volumes persist independently of containers.

**Verification:**
```bash
# Check volumes exist
ssh ***REMOVED-VPS*** "docker volume ls | grep openclaw"
# Output:
# qsw0sgsgwcog4wg88g448sgs_openclaw-config
# qsw0sgsgwcog4wg88g448sgs_openclaw-workspace
```

---

## ❌ TEMPORARY (Lost on Container Recreation)

### 1. Files Written Directly in Container
**Location:** Container filesystem (not in volumes)  
**Lost when:** Container is recreated or updated

**Examples:**
- ❌ Files in `/tmp` (tmpfs, cleared on restart)
- ❌ Files in `/var/tmp` (tmpfs, cleared on restart)
- ❌ Packages installed with `apt install` (unless in Dockerfile)
- ❌ Manual changes to system files

**Why temporary:** Container filesystem is ephemeral. Only volumes persist.

---

### 2. Running Processes
**Lost when:** Container restarts

**Examples:**
- ❌ Background processes started manually
- ❌ Tmux/screen sessions
- ❌ Active SSH connections

**Why temporary:** Processes don't survive container restarts.

---

## 🔄 What Happens on Container Recreation?

### Scenario 1: Code Change → Git Push → Coolify Rebuild

**What happens:**
1. You push changes to GitHub
2. Coolify webhook triggers
3. Coolify pulls latest code
4. Coolify builds new Docker image
5. Coolify stops old container
6. Coolify starts new container with same volumes

**What's preserved:**
- ✅ All Git repository changes (in new image)
- ✅ Skills in workspace volume
- ✅ Agent config in config volume
- ✅ Conversations and memory
- ✅ OAuth credentials

**What's lost:**
- ❌ Old container (replaced with new one)
- ❌ Container name changes (new timestamp)
- ❌ Running processes

**Current example:**
- Old container: `***REMOVED-DEPLOYMENT-ID***-072726042274`
- New container: `***REMOVED-DEPLOYMENT-ID***-103249061467`
- Skills still there: ✅ (in volume)

---

### Scenario 2: Container Restart (No Rebuild)

**What happens:**
1. Container stops
2. Container starts with same image and volumes

**What's preserved:**
- ✅ Everything in volumes
- ✅ Docker image (no rebuild)
- ✅ Skills, config, conversations

**What's lost:**
- ❌ Running processes
- ❌ Tmpfs contents (/tmp, /var/tmp)

---

### Scenario 3: Volume Deletion (DANGEROUS!)

**What happens:**
1. Someone manually deletes Docker volumes
2. All data in volumes is lost

**What's lost:**
- ❌ Skills in workspace
- ❌ Agent configuration
- ❌ Conversations and memory
- ❌ OAuth credentials
- ❌ Everything in volumes

**What's preserved:**
- ✅ Git repository (can rebuild)
- ✅ Docker image (can recreate)

**How to prevent:**
- Never run `docker volume rm` on openclaw volumes
- Backup volumes regularly

---

## 🛡️ Current Status (Verified)

### ✅ Skills Are Persistent
**Proof:** Skills survived container recreation from `072726042274` to `103249061467`

```bash
# Old container (stopped)
***REMOVED-DEPLOYMENT-ID***-072726042274

# New container (running)
***REMOVED-DEPLOYMENT-ID***-103249061467

# Skills still there
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-103249061467 ls /root/openclaw-workspace/skills/"
# Output: github  session-logs  summarize  weather ✅
```

### ✅ Skills Are Loaded
```bash
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-103249061467 openclaw skills list"
# Output: Skills (4/50 ready) ✅
```

---

## 📋 Persistence Checklist

| Item | Location | Persistent? | Survives Container Recreation? | Survives Volume Deletion? |
|------|----------|-------------|-------------------------------|---------------------------|
| Dockerfile changes | Git repo | ✅ Yes | ✅ Yes | ✅ Yes |
| Scripts in /app/scripts/ | Git repo → Image | ✅ Yes | ✅ Yes | ✅ Yes |
| Skills in workspace | Volume | ✅ Yes | ✅ Yes | ❌ No |
| Agent config | Volume | ✅ Yes | ✅ Yes | ❌ No |
| Conversations | Volume | ✅ Yes | ✅ Yes | ❌ No |
| OAuth credentials | Volume | ✅ Yes | ✅ Yes | ❌ No |
| Cron jobs | Volume | ✅ Yes | ✅ Yes | ❌ No |
| Running processes | Container | ❌ No | ❌ No | ❌ No |
| /tmp files | Tmpfs | ❌ No | ❌ No | ❌ No |
| Manual apt installs | Container | ❌ No | ❌ No | ❌ No |

---

## 🔧 How to Make Changes Permanent

### For Code/Configuration Changes:
1. Edit files locally in Git repository
2. Commit changes: `git commit -m "description"`
3. Push to GitHub: `git push origin main`
4. Coolify auto-deploys (5-10 minutes)

**Example:**
```bash
# Add new script
echo "#!/bin/bash" > scripts/my-script.sh
git add scripts/my-script.sh
git commit -m "feat: add my custom script"
git push origin main
# Wait for Coolify to rebuild
```

### For Skills:
Skills are automatically persistent because they're in the workspace volume.

**To add new skills:**
```bash
# Option 1: Via Telegram bot
Message: "Install the trello skill from clawhub"

# Option 2: Via container exec
ssh ***REMOVED-VPS*** "docker exec <container> clawhub install trello"
```

Skills will be in `/root/openclaw-workspace/skills/` (persistent volume).

### For Cron Jobs:
Cron jobs are stored in the config volume, so they're automatically persistent.

**To create:**
```bash
# Via Telegram bot (recommended)
Message: "Create a cron job that runs daily at 2 AM to check system health"
```

---

## 💾 Backup Strategy

### What to Backup:

#### 1. Git Repository (Most Important)
Already backed up on GitHub. This is your source of truth.

#### 2. Docker Volumes (Important)
```bash
# Backup workspace volume
ssh ***REMOVED-VPS*** "docker run --rm -v qsw0sgsgwcog4wg88g448sgs_openclaw-workspace:/data -v /root/backups:/backup alpine tar czf /backup/openclaw-workspace-$(date +%Y%m%d).tar.gz -C /data ."

# Backup config volume
ssh ***REMOVED-VPS*** "docker run --rm -v qsw0sgsgwcog4wg88g448sgs_openclaw-config:/data -v /root/backups:/backup alpine tar czf /backup/openclaw-config-$(date +%Y%m%d).tar.gz -C /data ."
```

#### 3. Environment Variables
Backup your `.env` file or Coolify environment variables (contains API keys).

### Restore from Backup:
```bash
# Restore workspace
ssh ***REMOVED-VPS*** "docker run --rm -v qsw0sgsgwcog4wg88g448sgs_openclaw-workspace:/data -v /root/backups:/backup alpine tar xzf /backup/openclaw-workspace-20260204.tar.gz -C /data"

# Restore config
ssh ***REMOVED-VPS*** "docker run --rm -v qsw0sgsgwcog4wg88g448sgs_openclaw-config:/data -v /root/backups:/backup alpine tar xzf /backup/openclaw-config-20260204.tar.gz -C /data"
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Editing Files Directly in Container
```bash
# DON'T DO THIS
ssh ***REMOVED-VPS*** "docker exec <container> nano /app/scripts/bootstrap.sh"
```
**Why bad:** Changes lost on next deployment.  
**Do instead:** Edit locally, commit, push to GitHub.

### ❌ Mistake 2: Installing Packages Manually
```bash
# DON'T DO THIS
ssh ***REMOVED-VPS*** "docker exec <container> apt install some-package"
```
**Why bad:** Lost on container recreation.  
**Do instead:** Add to Dockerfile, commit, push.

### ❌ Mistake 3: Storing Important Data in /tmp
```bash
# DON'T DO THIS
ssh ***REMOVED-VPS*** "docker exec <container> cp important-file.txt /tmp/"
```
**Why bad:** /tmp is tmpfs, cleared on restart.  
**Do instead:** Store in `/root/openclaw-workspace/` (persistent volume).

### ❌ Mistake 4: Deleting Volumes
```bash
# DON'T DO THIS
ssh ***REMOVED-VPS*** "docker volume rm qsw0sgsgwcog4wg88g448sgs_openclaw-workspace"
```
**Why bad:** Loses all skills, conversations, memory.  
**Do instead:** Backup first, or never delete.

---

## ✅ Best Practices

### 1. Always Use Git for Code Changes
- Edit locally
- Commit with meaningful messages
- Push to GitHub
- Let Coolify handle deployment

### 2. Use Volumes for Data
- Skills → `/root/openclaw-workspace/skills/`
- Config → `/root/.openclaw/`
- Never store important data outside volumes

### 3. Backup Regularly
- Git repository (automatic via GitHub)
- Docker volumes (manual, weekly recommended)
- Environment variables (manual, after changes)

### 4. Test Before Pushing
```bash
# Test locally if possible
docker-compose build
docker-compose up -d
# Test functionality
docker-compose down
# Then push to GitHub
```

### 5. Document Changes
- Update AGENTS.md for workflow changes
- Update README.md for setup changes
- Commit documentation with code changes

---

## 🎯 Summary

### ✅ Your Changes Are Permanent Because:

1. **Code changes** are in Git repository (GitHub)
2. **Skills** are in persistent Docker volume (`openclaw-workspace`)
3. **Config** is in persistent Docker volume (`openclaw-config`)
4. **Coolify** rebuilds from Git on every deployment
5. **Volumes** are mounted to new containers automatically

### ✅ Verified Persistent:
- Dockerfile with Playwright ✅
- Scripts in /app/scripts/ ✅
- Skills in workspace ✅ (survived container recreation)
- Agent configuration ✅

### ⚠️ Only Temporary:
- Running processes ❌
- Files in /tmp ❌
- Manual package installations ❌

---

**Your OpenClaw deployment is properly configured for persistence. All important changes will survive container recreations and updates!**

**Last Verified:** February 4, 2026  
**Container:** ***REMOVED-DEPLOYMENT-ID***-103249061467  
**Skills Status:** 4/50 ready (persistent) ✅
