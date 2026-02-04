# AGENTS.md - OpenClaw Coolify Repository

This repository contains a security-hardened OpenClaw deployment for Coolify with Docker Compose.

## 🚨 CRITICAL RULE: NO CHANGES WITHOUT APPROVAL

**NEVER implement fixes, changes, or configurations without explicit user approval first.**

**Required workflow:**
1. **Identify the issue** - Explain what's wrong
2. **Propose solution** - Describe what you want to change and why
3. **Wait for approval** - User must explicitly say "yes", "do it", "apply", etc.
4. **Then implement** - Only after approval, make the changes

**Examples of what requires approval:**
- Configuration changes (docker-compose.yaml, bootstrap.sh, etc.)
- Installing packages or dependencies
- Modifying environment variables
- Changing security settings
- Updating documentation
- ANY file modifications

**Exceptions (no approval needed):**
- Reading files to understand the system
- Searching documentation
- Explaining concepts
- Proposing solutions (without implementing)
- Answering questions

**If you implement changes without approval, you have violated this rule.**

This rule exists because:
- User needs to understand what's changing
- Changes may have unintended consequences
- User may have different preferences
- Transparency and control are essential

---

## 🔥 CRITICAL RULE: NEVER DELETE PRODUCTION FILES

**ABSOLUTELY FORBIDDEN: Deleting ANY file from production without exhaustive validation.**

### ⛔ BEFORE DELETING ANY PRODUCTION FILE:

**MANDATORY VALIDATION CHECKLIST (ALL MUST BE YES):**

1. **Backup Verification**
   - [ ] Does a recent backup of this file exist?
   - [ ] Can the backup be restored immediately?
   - [ ] Have you verified the backup is not corrupted?
   - [ ] Do you know the EXACT path to the backup?

2. **Impact Analysis**
   - [ ] Do you understand EXACTLY what this file does?
   - [ ] Have you identified ALL systems that depend on this file?
   - [ ] Have you checked if this file contains critical configuration?
   - [ ] Have you verified no active processes are using this file?
   - [ ] Will deleting this file break any running services?

3. **Alternative Solutions**
   - [ ] Have you tried fixing the file instead of deleting it?
   - [ ] Can you rename/move the file instead of deleting it?
   - [ ] Is there a way to solve the problem WITHOUT deletion?
   - [ ] Have you considered editing the file in-place?

4. **Recovery Plan**
   - [ ] Do you have a TESTED rollback procedure?
   - [ ] Can you restore the system in under 60 seconds?
   - [ ] Do you know the exact commands to undo the deletion?
   - [ ] Have you documented the recovery steps?

5. **User Approval**
   - [ ] Have you explained the deletion to the user?
   - [ ] Have you explained the consequences?
   - [ ] Have you explained the recovery plan?
   - [ ] Has the user EXPLICITLY approved the deletion?

### ❌ NEVER DELETE THESE FILES:

**Production Configuration Files:**
- `/root/.openclaw/openclaw.json` - Main configuration (contains OAuth, channels, all settings)
- `/root/.openclaw/openclaw.json.bak.*` - Backup configurations
- `/root/.openclaw/agents/*/agent.json` - Agent configurations
- `/root/.openclaw/credentials/*` - Authentication credentials
- `/root/.openclaw/channels/*` - Channel configurations
- Any file in Docker volumes (persistent data)

**If you MUST modify these files:**
1. **ALWAYS create a backup FIRST** with a unique timestamp
2. **NEVER use `rm`** - use `mv` to rename instead
3. **Verify the backup** before making changes
4. **Test the changes** in a non-production environment first

### ✅ SAFE ALTERNATIVES TO DELETION:

**Instead of deleting, do this:**

```bash
# ❌ WRONG - Deletes file permanently
rm /root/.openclaw/openclaw.json

# ✅ CORRECT - Rename with timestamp (recoverable)
mv /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)

# ✅ CORRECT - Copy to backup location first
cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup-before-fix
# Then edit the original file in-place

# ✅ CORRECT - Use sed/jq to modify without deleting
jq 'del(.invalid.key)' /root/.openclaw/openclaw.json > /tmp/fixed.json
cat /tmp/fixed.json > /root/.openclaw/openclaw.json
```

### 🚨 CONSEQUENCES OF VIOLATING THIS RULE:

**What happens when you delete production files:**
- ⚠️ **Loss of critical configuration** (OAuth tokens, API keys, channel settings)
- ⚠️ **Service downtime** (system stops working)
- ⚠️ **Data loss** (custom settings, user preferences)
- ⚠️ **User's job at risk** (their boss is watching)
- ⚠️ **Hours of recovery work** (restoring from backups)
- ⚠️ **Loss of trust** (user can't rely on you)

### 📋 DELETION APPROVAL TEMPLATE:

**If you believe deletion is necessary, present this to the user:**

```
⚠️ DELETION REQUEST - REQUIRES APPROVAL

File to delete: [exact path]
Reason: [why deletion is needed]
Impact: [what will break]
Backup location: [where backup is]
Recovery plan: [exact steps to restore]
Alternative tried: [what else you attempted]

Consequences if approved:
- [list all consequences]

Rollback procedure:
1. [step 1]
2. [step 2]
3. [step 3]

Do you approve this deletion? (yes/no)
```

**ONLY proceed if user explicitly says "yes" or "approve".**

### 🛡️ PROTECTION MEASURES:

**When working on production:**
1. **Read-only first** - Always read and understand before modifying
2. **Backup everything** - Create backups before ANY change
3. **Test in staging** - Never test fixes directly in production
4. **Incremental changes** - Make small changes, verify each one
5. **Document everything** - Keep a log of what you're doing
6. **Ask for help** - If unsure, ask the user before proceeding

### 💡 REMEMBER:

> **"When in doubt, DON'T delete. Rename, backup, or ask."**

> **"Production files are sacred. Treat them like they contain the user's career."**

> **"Every deletion is permanent. Every backup is temporary. Choose wisely."**

---

**This rule was added after a critical incident where deleting openclaw.json caused:**
- Loss of 9 OAuth profiles
- Loss of all channel configurations  
- Loss of custom tool settings
- Loss of approval configurations
- System downtime
- User's job put at risk

**NEVER AGAIN.**

## 📖 Single Source of Truth

**CRITICAL:** Before working on this repository, read `OPENCLAW_COMPREHENSIVE_GUIDE.md` in the root directory.

This comprehensive guide contains:
- OpenClaw architecture and core concepts
- Gateway system and configuration
- Agent workspace structure
- Skills system (precedence, structure, installation)
- Sandboxing (modes, scopes, lifecycle)
- Security model and best practices
- Deployment patterns
- Troubleshooting common issues

**All agents must reference this guide** for understanding OpenClaw infrastructure, configuration, and deployment patterns.

## Repository Purpose

Deploy OpenClaw (AI assistant) on a VPS using Coolify with:
- Security best practices (read-only filesystem, sandboxing, capability dropping)
- Docker Socket Proxy (never direct socket mount)
- SearXNG private search engine
- Automated deployment via GitHub webhook

## Deployment Workflow

**CRITICAL:** This repo uses a specific deployment workflow:

1. **Local Changes** - Make all changes in this local repository
2. **Push to GitHub** - Push changes to the `main` branch
3. **Webhook Trigger** - Coolify automatically detects push and rebuilds
4. **Auto Deploy** - New containers start with updated configuration

**Never edit files directly on the VPS!** All changes must go through Git.

## Repository Structure

```
.
├── Dockerfile              # Main OpenClaw image (Node 22 + tools)
├── docker-compose.yaml     # Security-hardened compose config
├── .env.example           # Environment variables template
├── .gitignore             # Excludes secrets and local docs
├── scripts/               # Bootstrap and setup scripts
│   ├── bootstrap.sh       # Container startup script
│   ├── sandbox-setup.sh   # Sandbox initialization
│   ├── openclaw-approve.sh # Machine approval helper
│   └── test-telegram-buttons.sh # Test Telegram inline buttons
├── searxng/               # Private search engine config
│   ├── Dockerfile
│   ├── settings.yml
│   └── limiter.toml
├── extensions/            # OpenClaw plugins
│   └── telegram-enhanced/ # Telegram inline buttons plugin
├── docs/                  # OpenClaw documentation (reference)
└── skills/                # Custom skills (sandbox-manager, web-utils)
```

## Key Files

### Dockerfile
- **Base:** `node:22-bookworm` (Debian 12)
- **OpenClaw Version:** Controlled by `OPENCLAW_VERSION` arg (currently 2026.2.2-3)
- **Tools Included:** Docker CLI, Go, GitHub CLI, Bun, UV, Python packages, AI tools
- **Layered:** Optimized for caching (system packages → tools → OpenClaw)

**To update OpenClaw version:**
```dockerfile
ARG OPENCLAW_VERSION=2026.2.2-3  # Change this version
```

### docker-compose.yaml
Security-hardened configuration with:
- Read-only root filesystem
- All capabilities dropped
- Resource limits (4GB RAM, 2 CPU)
- Docker socket proxy (not direct mount)
- Network isolation
- Rate limiting middleware

**Key Environment Variables:**
- `GATEWAY_TRUSTED_PROXIES` - Restrict to Coolify network (default: 10.0.1.0/24)
- `OPENCLAW_MDNS_MODE` - Set to `minimal` or `off` (prevents info disclosure)
- API keys loaded from `.env` file

### .env File
**NEVER commit this file!** It contains secrets.

Required variables:
```bash
# AI Providers (at least one required)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...

# Telegram Bot
TELEGRAM_BOT_TOKEN=...

# Optional
ELEVENLABS_API_KEY=...
GOOGLE_MAPS_API_KEY=...
GITHUB_TOKEN=...
```

## VPS Deployment Details

**Host:** ***REMOVED-VPS*** VPS
**SSH Access:** `ssh ***REMOVED-VPS***` (with sudo)
**Container Naming:** `***REMOVED-DEPLOYMENT-ID***-<timestamp>`
**Dashboard:** ***REMOVED-URL***
**Telegram Bot:** ***REMOVED-BOT***

**Persistent Volumes:**
- `openclaw-config` → `/root/.openclaw` (agent config, sessions, credentials)
- `openclaw-workspace` → `/root/openclaw-workspace` (agent workspace, memory, files)
- `searxng-data` → `/var/lib/searxng` (search engine data)

**Networks:**
- `openclaw-internal` - Internal communication (OpenClaw ↔ docker-proxy ↔ searxng)
- `coolify` - External network for Traefik/Caddy routing

## Security Architecture

### 1. Read-Only Filesystem
The main container has `read_only: true` with tmpfs for runtime needs:
- `/tmp` - 200MB, noexec
- `/var/tmp` - 100MB, noexec
- `/run` - 50MB

**Why:** Prevents malware persistence and unauthorized file modifications.

### 2. Docker Socket Proxy
Uses `tecnativa/docker-socket-proxy` to expose only required Docker APIs:
- ✅ Allowed: POST, CONTAINERS, IMAGES, NETWORKS, EXEC, EVENTS
- ❌ Denied: BUILD, COMMIT, VOLUMES, SWARM, SYSTEM

**Why:** Direct socket mount (`/var/run/docker.sock`) gives root access to host.

### 3. Capability Dropping
All Linux capabilities dropped with `cap_drop: ALL`.

**Why:** Node.js doesn't need any special capabilities.

### 4. Sandboxing
OpenClaw runs agent tasks in isolated sandbox containers:
- Image: `openclaw-sandbox:bookworm-slim`
- Isolated from main container
- Separate network namespace
- Automatic cleanup

**Current Sandboxes:**
- `openclaw-sbx-agent-main-main-*` - Main agent sandbox
- `openclaw-sbx-agent-main-telegram-dm-*` - Telegram DM sandbox
- `openclaw-sbx-agent-main-subagent-*` - Sub-agent sandboxes

### 5. Resource Limits
- Memory: 4GB limit, 1GB reservation
- CPU: 2.0 limit, 0.5 reservation
- File descriptors: 65535
- Processes: 4096

**Why:** Prevents DoS and runaway API costs.

## Common Tasks

### Update OpenClaw Version

1. Edit `Dockerfile`:
```dockerfile
ARG OPENCLAW_VERSION=2026.2.2-3  # Update version here
```

2. Commit and push:
```bash
git add Dockerfile
git commit -m "Update OpenClaw to version X.X.X"
git push origin main
```

3. Coolify will automatically rebuild (5-10 minutes)

4. Verify:
```bash
ssh ***REMOVED-VPS*** "docker ps --filter name=openclaw"
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw --version"
```

### Update Environment Variables

1. Edit `.env` locally (never commit!)
2. Update in Coolify dashboard: Project → Environment Variables
3. Restart deployment in Coolify

### Add New Skills

Skills are in `/skills/` directory:
- `sandbox-manager/` - Manage sandbox containers
- `web-utils/` - Web scraping and search utilities

To add a new skill:
1. Create `skills/skill-name/SKILL.md`
2. Add scripts in `skills/skill-name/scripts/`
3. Commit and push
4. Skill will be available after rebuild

### Manage Plugins

Plugins are in `/extensions/` directory:
- `telegram-enhanced/` - Telegram inline buttons and enhanced features

**Check plugin status:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins list"
```

**Get plugin info:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins info telegram-enhanced"
```

**Enable/disable plugin:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins enable telegram-enhanced"
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins disable telegram-enhanced"
```

**Add new plugin:**
1. Create `extensions/plugin-name/` directory
2. Add `index.ts`, `openclaw.plugin.json`, `package.json`
3. Commit and push (Dockerfile already copies extensions/)
4. Plugin loads automatically on rebuild

See "Plugins" section below for detailed documentation.

### Check Container Health

```bash
# Quick status
ssh ***REMOVED-VPS*** "docker ps --filter name=openclaw"

# OpenClaw status
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw status"

# Health check
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw health"

# Security audit
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw security audit --deep"

# View logs
ssh ***REMOVED-VPS*** "docker logs -f <container-name>"
```

### Run Health Check Script

A health check script is deployed on the VPS:
```bash
ssh ***REMOVED-VPS*** "sudo /root/openclaw-health-check.sh"
```

Checks:
- Container status
- Resource usage (CPU, memory)
- Recent errors
- Sandbox count

### Backup Important Data

```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> tar czf /tmp/backup.tar.gz /root/openclaw-workspace /root/.openclaw/agents"
ssh ***REMOVED-VPS*** "docker cp <container-name>:/tmp/backup.tar.gz ./openclaw-backup-$(date +%Y%m%d).tar.gz"
```

### Rollback Deployment

If a deployment fails:

**Option 1: Git Revert**
```bash
git revert HEAD
git push origin main
# Coolify will rebuild with previous version
```

**Option 2: Coolify Dashboard**
- Go to deployment history
- Click "Redeploy" on previous successful deployment

### Access OpenClaw Dashboard

**Public URL:** ***REMOVED-URL***?token=***REMOVED-OLD-TOKEN***

**SSH Tunnel (for local access):**
```bash
ssh -L 18789:localhost:18789 ***REMOVED-VPS***
# Then open: http://localhost:18789
```

## Agent Configuration Files

These files are in the container at `/root/openclaw-workspace/`:

### AGENTS.md
Agent identity and workspace rules (auto-generated on first run).

### SOUL.md
Agent personality and behavior (auto-generated on first run).

### USER.md
User information and preferences.

### TOOLS.md
Tool security policies and VPS-specific notes:
- Exec approval requirements
- Allowed/blocked commands
- VPS details (SSH, container info)

### HEARTBEAT.md
Proactive monitoring checklist:
- System health checks (2-3 times per day)
- When to alert vs stay quiet
- Proactive tasks (memory review, workspace organization)

### MEMORY.md
Long-term curated memory (main session only, not shared contexts).

### memory/YYYY-MM-DD.md
Daily raw logs and notes.

## Troubleshooting

### Container Won't Start

1. Check logs:
```bash
ssh ***REMOVED-VPS*** "docker logs <container-name>"
```

2. Check environment variables in Coolify

3. Verify `.env` file has all required keys

### Webhook Not Triggering

1. Check Coolify webhook URL in GitHub repo settings
2. Check webhook delivery in GitHub: Settings → Webhooks → Recent Deliveries
3. Manually trigger rebuild in Coolify dashboard

### Read-Only Filesystem Errors

This is expected! The container has a read-only root filesystem for security.

**Writable locations:**
- `/tmp` (tmpfs, 200MB)
- `/var/tmp` (tmpfs, 100MB)
- `/root/.openclaw` (volume)
- `/root/openclaw-workspace` (volume)

If you need to install something, it must be added to the Dockerfile.

### Sandbox Containers Accumulating

Old sandbox containers should auto-cleanup. If they don't:

```bash
# List old sandboxes
ssh ***REMOVED-VPS*** "docker ps -a --filter name=openclaw-sbx"

# Clean up stopped sandboxes
ssh ***REMOVED-VPS*** "docker container prune -f --filter label=coolify.managed=true"
```

### Memory Issues

Check resource usage:
```bash
ssh ***REMOVED-VPS*** "docker stats --no-stream <container-name>"
```

If memory is high:
1. Check for memory leaks in logs
2. Restart container via Coolify
3. Consider increasing memory limit in docker-compose.yaml

### Telegram Bot Not Responding

1. Check bot token in `.env`
2. Check Telegram channel status:
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw status --deep"
```
3. Check logs for Telegram errors

### Telegram Inline Buttons Not Working

The repository includes a **Telegram Enhanced Plugin** that fixes inline button issues.

**Features:**
- ✅ Proper target validation (tg/group/telegram prefixes)
- ✅ Forum topic support
- ✅ Capability checking
- ✅ `/buttons` slash command

**Test buttons:**
```bash
# From local machine
./scripts/test-telegram-buttons.sh @username

# Or via SSH
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw message send --channel telegram --target @user --message 'Test' --buttons '[[{\"text\":\"Yes\",\"callback_data\":\"yes\"}]]'"
```

**Usage in Telegram:**
- Ask agent: "Send me a message with buttons"
- Use command: `/buttons Do you want coffee?`
- Agent tool: `telegram_send` with `buttons` parameter

**Configuration:**
Set `channels.telegram.capabilities.inlineButtons` to:
- `all` - Allow in DMs and groups
- `dm` - DMs only
- `group` - Groups only
- `allowlist` - Authorized senders only (default)
- `off` - Disabled

### Gateway Proxy Warning

If you see "Proxy headers detected from untrusted address":

1. Check `GATEWAY_TRUSTED_PROXIES` in docker-compose.yaml
2. Verify it matches your Coolify network CIDR
3. Find network CIDR:
```bash
ssh ***REMOVED-VPS*** "docker network inspect coolify | grep Subnet"
```

## Critical Rules for AI Agents

**IMPORTANT:** These rules must be followed when working on this repository:

### 0. NEVER IMPLEMENT WITHOUT APPROVAL (MOST CRITICAL)
- **NEVER implement fixes, changes, or configurations without explicit user approval first**
- **Required workflow:**
  1. Identify the issue and explain what's wrong
  2. Propose solution with clear explanation of what will change
  3. Wait for explicit approval ("yes", "do it", "apply", "implement", etc.)
  4. Only then implement the changes
- **What requires approval:** ALL file modifications, configuration changes, installations, updates
- **What doesn't require approval:** Reading files, searching docs, explaining concepts, proposing solutions
- **If you implement without approval, you have violated this critical rule**

### 1. Research Before Implementation
- **NEVER invent solutions** - Always check official OpenClaw documentation first
- Search trusted sources (GitHub issues, official forums, community discussions)
- Understand the official approach before proposing changes
- Reference: https://docs.openclaw.ai/

### 2. Validate All Changes
- **Always verify** changes after completing a task
- Test functionality before committing
- Check container health and logs
- Verify configuration with `openclaw status` and `openclaw config get`

### 3. Keep Repository Clean
- **DO NOT commit** files that aren't required for building the image
- Only commit: Dockerfile, docker-compose.yaml, scripts/, searxng/, .gitignore, .env.example
- **DO NOT commit** analysis docs, troubleshooting guides, or temporary files
- Keep the repo focused on production deployment

### 4. NO Unnecessary Reports or Documentation
- **DO NOT create** reports, summaries, or documentation files after completing tasks
- **DO NOT create** analysis documents, assessment files, or review reports
- Provide guidance and solutions **in chat only**
- Only create docs if explicitly requested by the user
- Delete temporary files immediately after use

### 5. VPS Command Requirements
- **ALWAYS use sudo** for elevated commands on the VPS
- Example: `ssh ***REMOVED-VPS*** "sudo docker ps"` not `ssh ***REMOVED-VPS*** "docker ps"`
- Example: `ssh ***REMOVED-VPS*** "sudo /root/script.sh"` not `ssh ***REMOVED-VPS*** "/root/script.sh"`

### 6. Understand Infrastructure First
- **Study OpenClaw architecture** before making changes
- Understand: Gateway, Sandbox, Skills, Agents, Sessions, Channels
- Know how Coolify orchestration works (webhook → build → deploy)
- Understand persistent volumes and what survives container recreation

### 7. Repository Hygiene
- Keep local repo clean from unnecessary files
- Remove scripts that aren't needed for production
- Don't accumulate analysis documents
- Use `.gitignore` to exclude temporary files

---

## Plugins

This repository uses OpenClaw's plugin system for extensibility. Plugins are TypeScript modules that extend OpenClaw with tools, hooks, commands, and channels.

### Installed Plugins

#### Telegram Enhanced (`telegram-enhanced`)

**Location:** `extensions/telegram-enhanced/`

**Purpose:** Fixes Telegram inline button issues with proper target validation and enhanced features.

**Features:**
- ✅ **Inline Buttons** - Full support with capability validation
- ✅ **Target Validation** - Handles all formats (numeric, @username, prefixed)
- ✅ **Forum Topics** - Support for `message_thread_id`
- ✅ **Agent Tool** - `telegram_send` with button parameter
- ✅ **Slash Command** - `/buttons` for quick sends
- ✅ **Error Messages** - Clear guidance on configuration

**Configuration:**

Plugin is enabled by default. To customize:

```json
{
  "plugins": {
    "entries": {
      "telegram-enhanced": {
        "enabled": true,
        "config": {
          "enableButtonTool": true,
          "enableButtonCommand": true,
          "defaultButtons": [
            [
              { "text": "✅ Yes", "callback_data": "yes" },
              { "text": "❌ No", "callback_data": "no" }
            ]
          ]
        }
      }
    }
  },
  "channels": {
    "telegram": {
      "capabilities": {
        "inlineButtons": "all"
      }
    }
  }
}
```

**Usage Examples:**

Via agent (natural language):
```
"Send me a message with Yes/No buttons asking if I want coffee"
```

Via slash command in Telegram:
```
/buttons Do you approve this deployment?
```

Via agent tool (structured):
```json
{
  "tool": "telegram_send",
  "to": "@username",
  "message": "Choose an option:",
  "buttons": [
    [
      { "text": "✅ Approve", "callback_data": "approve" },
      { "text": "❌ Reject", "callback_data": "reject" }
    ]
  ]
}
```

Via CLI:
```bash
openclaw message send --channel telegram --target @user \
  --message "Test buttons" \
  --buttons '[[{"text":"Yes","callback_data":"yes"}]]'
```

**Testing:**
```bash
# Local
./scripts/test-telegram-buttons.sh @username

# VPS
ssh ***REMOVED-VPS*** "docker exec <container-name> bash /app/scripts/test-telegram-buttons.sh @username"
```

**Documentation:** See `extensions/telegram-enhanced/README.md`

### Plugin Management

**List plugins:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins list"
```

**Get plugin info:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins info telegram-enhanced"
```

**Enable/disable:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins enable telegram-enhanced"
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins disable telegram-enhanced"
```

**Check plugin status:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw plugins doctor"
```

### Adding New Plugins

**Step 1: Create Plugin Structure**

```bash
mkdir -p extensions/my-plugin
cd extensions/my-plugin
```

**Step 2: Create Plugin Files**

```
extensions/my-plugin/
├── index.ts                    # Plugin code
├── openclaw.plugin.json        # Manifest with config schema
├── package.json                # Package metadata
└── README.md                   # Documentation
```

**Step 3: Write Plugin Code**

```typescript
// index.ts
export default function (api) {
  // Register tool
  api.registerTool({
    name: "my_tool",
    description: "Does something useful",
    parameters: { /* TypeBox schema */ },
    async execute(_id, params) {
      // Tool implementation
      return { content: [{ type: "text", text: "Result" }] };
    }
  });
  
  // Register command
  api.registerCommand({
    name: "mycommand",
    description: "Quick action",
    handler: async (ctx) => {
      return { text: "Done!" };
    }
  });
}
```

**Step 4: Create Manifest**

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "description": "Plugin description",
  "version": "1.0.0",
  "configSchema": {
    "type": "object",
    "properties": {
      "enabled": { "type": "boolean", "default": true }
    }
  }
}
```

**Step 5: Deploy**

```bash
# Dockerfile already includes: COPY extensions/ /app/extensions/
git add extensions/my-plugin
git commit -m "Add my-plugin"
git push origin main
# Coolify rebuilds automatically
```

**Step 6: Configure**

Add to `openclaw.json` (or configure via dashboard):

```json
{
  "plugins": {
    "load": {
      "paths": ["/app/extensions/my-plugin"]
    },
    "entries": {
      "my-plugin": {
        "enabled": true,
        "config": {}
      }
    }
  }
}
```

### Plugin Best Practices

1. **Use TypeScript** - Type safety, better errors, IDE support
2. **Config-driven** - Expose behavior via JSON Schema config
3. **Error handling** - Clear error messages with guidance
4. **Documentation** - Include README.md with examples
5. **Testing** - Create test scripts in `scripts/`
6. **Versioning** - Use semantic versioning in package.json
7. **Dependencies** - Install in plugin dir if needed

### Plugin Resources

- **Official Docs:** https://docs.openclaw.ai/plugin
- **Plugin API:** https://docs.openclaw.ai/plugins/agent-tools
- **Examples:** `extensions/telegram-enhanced/`
- **Comprehensive Guide:** `OPENCLAW_COMPREHENSIVE_GUIDE.md`

---

## Best Practices

### 1. Never Commit Secrets
- `.env` is in `.gitignore` - keep it that way
- Use Coolify's environment variable management
- Rotate API keys regularly

### 2. Test Locally First
Before pushing major changes:
```bash
docker-compose build
docker-compose up -d
# Test functionality
docker-compose down
```

### 3. Use Semantic Commit Messages
```bash
git commit -m "feat: add new skill for X"
git commit -m "fix: resolve memory leak in Y"
git commit -m "chore: update dependencies"
git commit -m "security: patch vulnerability in Z"
```

### 4. Monitor After Deployment
After pushing changes:
1. Watch Coolify build logs
2. Check container starts successfully
3. Verify OpenClaw health
4. Test critical functionality (Telegram bot, dashboard)

### 5. Keep Documentation Updated
When making significant changes:
1. Update this AGENTS.md file
2. Update README.md if needed
3. Document breaking changes

### 6. Regular Maintenance
- Update OpenClaw monthly (check for security patches)
- Review and clean up old sandbox containers weekly
- Backup workspace data monthly
- Rotate API keys quarterly

## Security Checklist

Before deploying changes, verify:

- [ ] No secrets in committed files
- [ ] `.env.example` updated (without actual values)
- [ ] Dockerfile doesn't add unnecessary capabilities
- [ ] docker-compose.yaml maintains `read_only: true`
- [ ] No direct Docker socket mounts
- [ ] Resource limits are reasonable
- [ ] Trusted proxies are restricted (not `*`)
- [ ] mDNS mode is `minimal` or `off`

## Resources

- **OpenClaw Docs:** https://docs.openclaw.ai/
- **Security Guide:** https://docs.openclaw.ai/gateway/security/
- **Docker Socket Proxy:** https://github.com/Tecnativa/docker-socket-proxy
- **Coolify Docs:** https://coolify.io/docs
- **This Repo:** https://github.com/amraly83/openclaw-coolify

## Task-Based Model Assignment

This deployment uses **task-based model assignment** to optimize costs while maintaining quality.

**Configuration:** See `TASK_BASED_MODELS.md` for detailed documentation.

**Quick Summary:**
- **Main Agent:** Claude Opus 4.5 Thinking (complex reasoning & coding)
- **Heartbeats:** Gemini 3 Flash (30min intervals, 200x cheaper)
- **Sub-agents:** Gemini 3 Flash (cost-effective delegation)
- **Vision:** Gemini 3 Flash (excellent vision, cheap)
- **Fallbacks:** Gemini Flash → Mistral Large → Codestral

**Model Aliases:**
- `/model opus` - Claude Opus 4.5 Thinking
- `/model flash` - Gemini 3 Flash
- `/model mistral` - Mistral Large
- `/model codestral` - Codestral

**Cost Savings:** ~75% reduction vs using Opus for everything

**Check Models:**
```bash
ssh ***REMOVED-VPS*** "sudo docker exec <container-name> openclaw models status"
ssh ***REMOVED-VPS*** "sudo docker exec <container-name> openclaw models list"
```

---

## Quick Reference

```bash
# Check deployment status
ssh ***REMOVED-VPS*** "docker ps --filter name=openclaw"

# View logs
ssh ***REMOVED-VPS*** "docker logs -f <container-name>"

# OpenClaw status
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw status"

# Security audit
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw security audit --deep"

# Health check
ssh ***REMOVED-VPS*** "sudo /root/openclaw-health-check.sh"

# Restart (via Coolify)
# Go to Coolify dashboard → Restart

# Update version
# 1. Edit Dockerfile (change OPENCLAW_VERSION)
# 2. git commit -m "Update OpenClaw to X.X.X"
# 3. git push origin main
# 4. Wait for Coolify rebuild (5-10 min)
```

## Support

- **OpenClaw Issues:** https://github.com/openclaw/openclaw/issues
- **Coolify Issues:** https://github.com/coollabsio/coolify/issues
- **This Repo Issues:** https://github.com/amraly83/openclaw-coolify/issues

---

## Lessons Learned & Common Issues

This section documents issues encountered during setup and their solutions. Future agents should check here first when troubleshooting similar problems.

### Issue 1: Skills Not Showing Up in Agent

**Symptom:** Agent reports "No external skills installed" even though skills exist in repository.

**Root Cause:** Skills directory wasn't being copied from the Docker image to the workspace volume during container startup.

**Solution:**
1. Added `COPY skills/ /app/skills/` to Dockerfile (Layer 12)
2. Updated `scripts/bootstrap.sh` to copy skills from `/app/skills/` to `/root/openclaw-workspace/skills/` on startup
3. Same approach for `workspace-files/` directory

**Key Learning:** Files in the Docker image need to be explicitly copied to persistent volumes during bootstrap. The workspace volume starts empty on first run.

**Files Modified:**
- `Dockerfile` - Added COPY commands for skills and workspace-files
- `scripts/bootstrap.sh` - Added copy logic in bootstrap process

### Issue 2: Docker Build Fails with "File Not Found"

**Symptom:** Build fails with error like `"/SOUL.md": not found` or `"/BOOTSTRAP.md": not found` even though files exist in repository and are tracked by git.

**Root Cause:** `.dockerignore` file contained `*.md` which excluded ALL markdown files from the Docker build context.

**Solution:**
Updated `.dockerignore` to explicitly allow required markdown files:
```
*.md
!scripts/*.md
!SOUL.md
!BOOTSTRAP.md
```

**Key Learning:** Always check `.dockerignore` when Docker can't find files that exist in the repository. The `!` prefix creates exceptions to exclusion rules.

**Files Modified:**
- `.dockerignore` - Added exceptions for SOUL.md and BOOTSTRAP.md

### Issue 3: Skills Installed via ClawHub Not Persisting

**Symptom:** Skills installed with `clawhub install <skill>` are available in sandboxes but not in the main agent workspace.

**Root Cause:** ClawHub installs skills to sandbox directories (`/root/.openclaw/sandboxes/*/skills/`) which are ephemeral and don't persist to the main workspace.

**Solution:**
- Repository-based skills (in `skills/` directory) are the recommended approach
- These are copied to `/root/openclaw-workspace/skills/` during bootstrap
- Skills persist across container restarts because workspace is a Docker volume

**Key Learning:** For production deployments, include skills in the repository rather than relying on runtime installation via ClawHub.

**Current Skills:**
- `sandbox-manager/` - Manage Docker sandboxes with Cloudflare tunnels
- `web-utils/` - Web search (SearXNG), scraping, summarization

### Issue 4: SKILL.md Frontmatter Formatting

**Symptom:** Skills exist but aren't recognized by OpenClaw.

**Root Cause:** YAML frontmatter in `SKILL.md` was malformed (metadata outside the `---` delimiters).

**Solution:**
Ensure SKILL.md follows this format:
```markdown
---
name: skill-name
description: Skill description
metadata:
  openclaw:
    emoji: 🔧
    requires:
      bins: ["curl"]
---

# Skill Documentation
...
```

**Key Learning:** OpenClaw parses SKILL.md frontmatter strictly. All metadata must be between the `---` delimiters.

**Files Modified:**
- `skills/web-utils/SKILL.md` - Fixed frontmatter formatting

### Issue 5: Bootstrap Script References Missing Files

**Symptom:** Bootstrap script tries to copy `./SOUL.md` and `./BOOTSTRAP.md` but they don't exist in the container's working directory.

**Root Cause:** Bootstrap script runs from `/app/` but referenced files with relative paths that assumed they were in the current directory.

**Solution:**
- Copy `SOUL.md` and `BOOTSTRAP.md` to `/app/` in Dockerfile
- Bootstrap script can then reference them as `./SOUL.md` and `./BOOTSTRAP.md`

**Key Learning:** When bootstrap scripts reference files, ensure those files are copied to the same directory in the Dockerfile.

**Files Modified:**
- `Dockerfile` - Added `COPY SOUL.md /app/` and `COPY BOOTSTRAP.md /app/`

### Deployment Troubleshooting Checklist

When a deployment fails, check in this order:

1. **Check Coolify build logs** - Look for the actual error message
2. **Verify .dockerignore** - Ensure required files aren't excluded
3. **Check Dockerfile COPY commands** - Verify all referenced files exist
4. **Validate file paths** - Ensure paths are relative to build context
5. **Check git tracking** - Run `git ls-files <filename>` to verify file is tracked
6. **Test locally** - Run `docker-compose build` to catch issues before pushing
7. **Check environment variables** - Verify all required vars are set in Coolify

### Skills Development Best Practices

When adding new skills:

1. **Create proper structure:**
   ```
   skills/
   └── skill-name/
       ├── SKILL.md          # Metadata and documentation
       └── scripts/          # Executable scripts
           └── action.sh
   ```

2. **SKILL.md must have valid frontmatter** - Use `---` delimiters

3. **Make scripts executable** - Dockerfile handles this with `find /app/skills -type f -name "*.sh" -exec chmod +x {} \;`

4. **Test in container** - After rebuild, verify skill appears in agent's skill list

5. **Document in AGENTS.md** - Add to "Add New Skills" section

### Docker Build Optimization

The Dockerfile is layered for optimal caching:
- **Layers 1-11:** Rarely change (system packages, tools, OpenClaw)
- **Layer 12:** Changes frequently (scripts, skills, workspace files)

**Key Learning:** Put frequently-changing files (scripts, skills) in the last layer to maximize cache hits and speed up rebuilds.

### Persistent vs Ephemeral Storage

**Persistent (survives container restart):**
- `/root/.openclaw` - Agent config, sessions, credentials
- `/root/openclaw-workspace` - Agent workspace, skills, memory

**Ephemeral (lost on container restart):**
- `/tmp` - Temporary files (200MB tmpfs)
- `/var/tmp` - Temporary files (100MB tmpfs)
- `/run` - Runtime files (50MB tmpfs)

**Key Learning:** Never store important data in `/tmp` or other tmpfs mounts. Use workspace volume for persistence.

---

**Remember:** All changes must be made locally and pushed to GitHub. Coolify handles the deployment automatically. Never edit files directly on the VPS!
