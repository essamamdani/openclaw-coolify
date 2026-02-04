# OpenClaw Infrastructure Guide

**Quick Reference for AI Agents**

---

## 🐳 Docker Connection

```bash
DOCKER_HOST=tcp://docker-proxy:2375
```

**Allowed:** POST, CONTAINERS, IMAGES, NETWORKS, EXEC, EVENTS, INFO, VERSION  
**Forbidden:** BUILD, COMMIT, VOLUMES, SWARM, SYSTEM

---

## 📦 Sandbox Creation Template

```bash
docker run -d \
  --name "openclaw-sbx-<project>-$(date +%s)" \
  --label "coolify.managed=true" \
  --label "coolify.applicationId=qsw0sgsgwcog4wg88g448sgs" \
  --label "openclaw.sandbox=true" \
  --label "openclaw.project=<project>" \
  --network openclaw-internal \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --read-only \
  --tmpfs /tmp:size=200M,noexec \
  --tmpfs /var/tmp:size=100M,noexec \
  --memory 1g --cpus 1.0 --pids-limit 256 \
  -v <project>-data:/app \
  <image> tail -f /dev/null
```

---

## 🗄️ State Database

**Location:** `/root/openclaw-workspace/sandboxes.db`

```sql
-- Check if exists
SELECT COUNT(*) FROM sandboxes WHERE name='<name>';

-- Add sandbox
INSERT INTO sandboxes (name, stack, title, url, volume_name)
VALUES ('<name>', '<stack>', '<title>', '<url>', '<volume>');

-- List all
SELECT * FROM sandboxes;

-- Delete
DELETE FROM sandboxes WHERE name='<name>';
```

---

## 🌐 Public Access

```bash
# Cloudflare tunnel
cloudflared tunnel --url http://localhost:<port> &

# Vercel deploy
docker exec <sandbox> vercel --prod --yes
```

---

## 🔐 Security Rules

1. ❌ Never mount Docker socket directly
2. ✅ Always drop ALL capabilities
3. ✅ Always use read-only root filesystem
4. ✅ Always set resource limits
5. ✅ Always use Coolify labels

---

## 📝 Key Paths

- **Workspace:** `/root/openclaw-workspace`
- **State DB:** `/root/openclaw-workspace/sandboxes.db`
- **Skills:** `/root/openclaw-workspace/skills/`
- **Memory:** `/root/openclaw-workspace/MEMORY.md`
- **Daily Logs:** `/root/openclaw-workspace/memory/YYYY-MM-DD.md`

---

## 🎯 Container Prefixes

- **Main:** `openclaw-qsw0sgsgwcog4wg88g448sgs-*`
- **Sandboxes:** `openclaw-sbx-agent-main-*`
- **Network:** `openclaw-internal`

**NEVER touch containers without these prefixes!**

---

## 📚 Full Guide

See `/root/openclaw-workspace/OPENCLAW_GUIDE.md` for complete documentation.
