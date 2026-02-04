# OpenClaw Agent Guide - Single Source of Truth

**For AI Agents Working with OpenClaw Infrastructure**

---

## 🧠 Identity & Purpose

**What OpenClaw Is:**
- Runtime Orchestrator for AI agents
- Manages sandboxes, sessions, channels, and tool execution
- Provides secure Docker-based execution environments

**What OpenClaw Is NOT:**
- Not a coding assistant (that's your job)
- Not a build system (use sandboxes for that)
- Not a direct shell replacement (use exec tool with approval)

**Your Role:**
- Understand user requirements
- Orchestrate sandboxes and deployments
- Manage state and memory
- Follow security protocols

---

## 🐳 Docker Access

### Connection Method
```bash
# Via secure proxy (NOT direct socket)
DOCKER_HOST=tcp://docker-proxy:2375
```

### Allowed Operations
✅ **POST** - Create containers  
✅ **CONTAINERS** - List/manage containers  
✅ **IMAGES** - Pull images  
✅ **NETWORKS** - Network management  
✅ **EXEC** - Execute commands in containers  
✅ **EVENTS** - Listen for events  
✅ **INFO/VERSION** - System info  

### Forbidden Operations
❌ **BUILD** - No arbitrary image building  
❌ **COMMIT** - No image creation from containers  
❌ **VOLUMES** - No direct volume access  
❌ **SWARM** - No swarm operations  
❌ **SYSTEM** - No system-wide operations  

### Container Identification Rules
**OpenClaw Containers:**
- Main: `***REMOVED-DEPLOYMENT-ID***-*`
- Sandboxes: `openclaw-sbx-agent-main-*`
- Docker Proxy: `***REMOVED-DEPLOYMENT-ID***-docker-proxy-*`
- SearXNG: `***REMOVED-DEPLOYMENT-ID***-searxng-*`

**NEVER touch containers without these prefixes!**

---

## 📦 Base Images (Approved)

Use these official images for sandboxes:

| Language/Stack | Image |
|----------------|-------|
| Node.js | `node:22-bookworm` |
| Python | `python:3.12-bookworm` |
| Go | `golang:1.23-bookworm` |
| PHP | `php:8.3-cli-bookworm` |
| Ruby | `ruby:3.3-bookworm` |
| Java | `eclipse-temurin:21-jdk-bookworm` |
| .NET | `mcr.microsoft.com/dotnet/sdk:8.0` |
| Rust | `rust:1.75-bookworm` |

**Security Rule:** Only use official images from Docker Hub or verified registries.

---

## 🚀 Sandbox Creation

### Command Template
```bash
docker run -d \
  --name "openclaw-sbx-<project-name>-$(date +%s)" \
  --label "coolify.managed=true" \
  --label "coolify.applicationId=qsw0sgsgwcog4wg88g448sgs" \
  --label "coolify.type=service" \
  --label "openclaw.sandbox=true" \
  --label "openclaw.project=<project-name>" \
  --network openclaw-internal \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --read-only \
  --tmpfs /tmp:size=200M,mode=1777,noexec \
  --tmpfs /var/tmp:size=100M,mode=1777,noexec \
  --tmpfs /run:size=50M,mode=755 \
  --memory 1g \
  --memory-swap 2g \
  --cpus 1.0 \
  --pids-limit 256 \
  -v <project-name>-data:/app \
  -e NODE_ENV=production \
  <base-image> \
  tail -f /dev/null
```

### Required Labels
- `coolify.managed=true` - Coolify will manage lifecycle
- `coolify.applicationId=qsw0sgsgwcog4wg88g448sgs` - Links to this deployment
- `openclaw.sandbox=true` - Identifies as sandbox
- `openclaw.project=<name>` - Project identifier

### Security Requirements
- `--cap-drop ALL` - Drop all Linux capabilities
- `--read-only` - Read-only root filesystem
- `--security-opt no-new-privileges:true` - Prevent privilege escalation
- Resource limits (memory, CPU, PIDs)
- tmpfs for writable directories

---

## 🗄️ State Management

### Database Location
```bash
/root/openclaw-workspace/sandboxes.db
```

### Schema
```sql
CREATE TABLE IF NOT EXISTS sandboxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    stack TEXT NOT NULL,
    title TEXT,
    url TEXT,
    tunnel_pid INTEGER,
    volume_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'running'
);
```

### State Rules
1. **Always check DB before creating** - Prevent duplicates
2. **Update status on changes** - Keep DB in sync
3. **Clean up on delete** - Remove DB entry when container is removed
4. **Persist to workspace** - DB is in persistent volume

### Accessing State
```bash
# List all sandboxes
sqlite3 /root/openclaw-workspace/sandboxes.db "SELECT * FROM sandboxes;"

# Check if sandbox exists
sqlite3 /root/openclaw-workspace/sandboxes.db \
  "SELECT COUNT(*) FROM sandboxes WHERE name='<name>';"

# Add sandbox
sqlite3 /root/openclaw-workspace/sandboxes.db \
  "INSERT INTO sandboxes (name, stack, title, url, volume_name) \
   VALUES ('<name>', '<stack>', '<title>', '<url>', '<volume>');"

# Delete sandbox
sqlite3 /root/openclaw-workspace/sandboxes.db \
  "DELETE FROM sandboxes WHERE name='<name>';"
```

---

## 🌐 Public Access

### Cloudflare Tunnels
```bash
# Start tunnel for a sandbox
cloudflared tunnel --url http://localhost:<port> &

# Get public URL from output
# Format: https://<random>.trycloudflare.com
```

### Vercel Deployment
```bash
# Deploy from sandbox
docker exec <sandbox-name> vercel --prod --yes
```

### URL Management
- Store URLs in sandboxes.db
- Update user with public URL
- Tunnels persist until container restart
- Use `tunnel_pid` to track tunnel process

---

## 🔧 Runtime Installation

**Problem:** Read-only filesystem prevents `npm install`, `pip install`, etc.

**Solutions:**

### Option 1: Install in Writable Volume
```bash
# Node.js
docker exec <sandbox> sh -c "cd /app && npm install"

# Python
docker exec <sandbox> sh -c "cd /app && pip install --target=/app/deps -r requirements.txt"
```

### Option 2: Use Package Managers with Cache
```bash
# Bun (faster than npm)
docker exec <sandbox> sh -c "cd /app && bun install"

# UV (faster than pip)
docker exec <sandbox> sh -c "cd /app && uv pip install -r requirements.txt"
```

### Option 3: Pre-install in Custom Image
For complex dependencies, create a custom image in the Dockerfile.

---

## 🔄 Recovery Protocol

### After Container Restart
1. **Check sandboxes.db** - Get list of sandboxes
2. **Verify containers exist** - `docker ps -a --filter name=openclaw-sbx`
3. **Restart stopped containers** - `docker start <name>`
4. **Recreate tunnels** - Cloudflare tunnels don't persist
5. **Update URLs** - Store new tunnel URLs in DB

### After Volume Loss (Rare)
1. **Recreate sandboxes.db** - Initialize schema
2. **Scan for orphaned containers** - `docker ps -a --filter label=openclaw.sandbox=true`
3. **Rebuild state** - Query containers for labels and reconstruct DB

### Monitoring Script
```bash
# Check sandbox health
for container in $(docker ps --filter label=openclaw.sandbox=true --format '{{.Names}}'); do
  echo "Checking $container..."
  docker exec $container echo "OK" || echo "FAILED: $container"
done
```

---

## 🔐 Security Rules

### 1. Never Mount Docker Socket Directly
❌ **WRONG:** `-v /var/run/docker.sock:/var/run/docker.sock`  
✅ **RIGHT:** Use `DOCKER_HOST=tcp://docker-proxy:2375`

### 2. Always Drop Capabilities
```bash
--cap-drop ALL
```

### 3. Always Use Read-Only Root
```bash
--read-only
--tmpfs /tmp:size=200M,mode=1777,noexec
```

### 4. Always Set Resource Limits
```bash
--memory 1g --memory-swap 2g --cpus 1.0 --pids-limit 256
```

### 5. Always Use Coolify Labels
```bash
--label "coolify.managed=true"
--label "coolify.applicationId=qsw0sgsgwcog4wg88g448sgs"
```

**Why:** These labels ensure Coolify manages the container lifecycle and cleanup.

---

## 📝 Memory Protocol

### What to Remember
- Sandbox names and their purposes
- Public URLs for active projects
- User preferences and patterns
- Common issues and solutions

### Where to Store
```bash
# Long-term memory (curated)
/root/openclaw-workspace/MEMORY.md

# Daily logs (raw)
/root/openclaw-workspace/memory/YYYY-MM-DD.md
```

### Memory Format
```markdown
# MEMORY.md

## Active Sandboxes
- **nextjs-blog** - Personal blog (https://abc123.trycloudflare.com)
- **fastapi-api** - REST API for mobile app (https://xyz789.trycloudflare.com)

## User Preferences
- Prefers Next.js for web projects
- Uses TypeScript by default
- Likes Tailwind CSS

## Common Patterns
- Always wants public URLs immediately
- Prefers Vercel for production deployments
- Uses GitHub for version control
```

---

## ✅ Deployment Checklist

When creating a new sandbox:

- [ ] 1. Check if sandbox name already exists in DB
- [ ] 2. Pull base image if not cached
- [ ] 3. Create Docker volume for persistence
- [ ] 4. Run container with all security flags
- [ ] 5. Verify container is running (`docker ps`)
- [ ] 6. Install dependencies in volume
- [ ] 7. Start application process
- [ ] 8. Create Cloudflare tunnel
- [ ] 9. Store sandbox info in DB
- [ ] 10. Provide user with public URL

---

## 🛠️ Common Commands

### Container Management
```bash
# List all OpenClaw containers
docker ps -a --filter label=coolify.applicationId=qsw0sgsgwcog4wg88g448sgs

# List sandboxes only
docker ps --filter label=openclaw.sandbox=true

# Stop sandbox
docker stop <sandbox-name>

# Remove sandbox
docker rm -f <sandbox-name>

# View logs
docker logs -f <sandbox-name>

# Execute command
docker exec <sandbox-name> <command>
```

### Volume Management
```bash
# List volumes
docker volume ls --filter label=coolify.managed=true

# Inspect volume
docker volume inspect <volume-name>

# Remove volume
docker volume rm <volume-name>
```

### Network Management
```bash
# List networks
docker network ls

# Inspect network
docker network inspect openclaw-internal

# Connect container to network
docker network connect openclaw-internal <container-name>
```

---

## 🚨 Troubleshooting

### Container Won't Start
1. Check logs: `docker logs <name>`
2. Verify image exists: `docker images`
3. Check resource limits: `docker stats`
4. Verify network exists: `docker network ls`

### Can't Install Dependencies
1. Verify volume is mounted: `docker inspect <name>`
2. Check disk space: `df -h`
3. Try alternative package manager (bun, uv)
4. Consider pre-installing in Dockerfile

### Tunnel Not Working
1. Verify cloudflared is installed: `which cloudflared`
2. Check tunnel process: `ps aux | grep cloudflared`
3. Restart tunnel with new URL
4. Check container port is listening: `docker exec <name> netstat -tlnp`

### Database Locked
1. Check for concurrent writes
2. Use transactions for multiple operations
3. Add retry logic with exponential backoff

---

## 📚 Additional Resources

- **OpenClaw Docs:** https://docs.openclaw.ai/
- **Docker Security:** https://docs.docker.com/engine/security/
- **Coolify Docs:** https://coolify.io/docs
- **This Repo:** https://github.com/amraly83/openclaw-coolify

---

## 🎯 Quick Reference

**Container Prefix:** `***REMOVED-DEPLOYMENT-ID***-`  
**Sandbox Prefix:** `openclaw-sbx-agent-main-`  
**Network:** `openclaw-internal`  
**Docker Host:** `tcp://docker-proxy:2375`  
**Workspace:** `/root/openclaw-workspace`  
**State DB:** `/root/openclaw-workspace/sandboxes.db`  
**Skills:** `/root/openclaw-workspace/skills/`

---

**Remember:** You are an orchestrator, not a builder. Use sandboxes for execution, maintain state, follow security rules, and always verify your work.
