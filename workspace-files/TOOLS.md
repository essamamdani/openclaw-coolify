---
summary: "Local environment specifics and tool notes"
---
# TOOLS.md - Local Notes

This file contains environment-specific details for your VPS deployment.

## VPS Details

### SSH Access
- **Host:** [Your VPS hostname]
- **SSH Command:** `ssh [your-host]` (with sudo access)
- **Dashboard:** [Your dashboard URL]
- **Token:** (stored securely in container - use `openclaw config get gateway.auth.token` to retrieve)

### Container Information
- **Naming Pattern:** `openclaw-[deployment-id]-<timestamp>`
- **Network:** `coolify` (external), `openclaw-internal` (internal)
- **Volumes:**
  - `openclaw-config` → `/root/.openclaw`
  - `openclaw-workspace` → `/root/openclaw-workspace`

### Docker Configuration
- **Read-only filesystem:** Root filesystem is read-only for security
- **Writable locations:**
  - `/tmp` (200MB tmpfs, noexec)
  - `/var/tmp` (100MB tmpfs, noexec)
  - `/run` (50MB tmpfs)
  - `/root/.openclaw` (volume)
  - `/root/openclaw-workspace` (volume)
- **Docker Socket:** Via proxy (tecnativa/docker-socket-proxy), not direct mount
- **Capabilities:** All dropped (`cap_drop: ALL`)

### Security Constraints
- **Exec approval:** Required for shell commands
- **Sandbox mode:** `all` (all agents run in sandboxes)
- **Sandbox scope:** `session` (ephemeral, destroyed after session)
- **Workspace access:** `rw` (read-write)
- **Trusted proxies:** Restricted to Coolify network (10.0.1.0/24)
- **mDNS mode:** `minimal` or `off` (prevents info disclosure)

## Skills

### Available Skills
- **sandbox-manager** - Manage Docker sandbox containers
- **web-utils** - Web search (SearXNG), scraping, summarization
- **sag** - ElevenLabs TTS (if API key configured)
- **github** - GitHub operations (if token configured)

### Skill Locations
1. Workspace skills: `/root/openclaw-workspace/skills/` (highest precedence)
2. Managed skills: `/root/.openclaw/skills/` (ClawHub installs)
3. Bundled skills: `/usr/local/lib/openclaw/skills/` (shipped with OpenClaw)

## Deployment Workflow

**CRITICAL:** Never edit files directly on VPS!

1. Make changes locally in repository
2. Push to GitHub (`main` branch)
3. Coolify webhook triggers rebuild
4. New container deployed automatically

## Common Commands

```bash
# Check container status
ssh ***REMOVED-VPS*** "docker ps --filter name=openclaw"

# View logs
ssh ***REMOVED-VPS*** "docker logs -f <container-name>"

# OpenClaw status
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw status"

# Security audit
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw security audit --deep"

# Health check
ssh ***REMOVED-VPS*** "sudo /root/openclaw-health-check.sh"
```

## API Keys

Configured via environment variables in Coolify:
- `ANTHROPIC_API_KEY` - Claude models
- `OPENAI_API_KEY` - OpenAI models (optional)
- `TELEGRAM_BOT_TOKEN` - Telegram bot (@[your-bot-username])
- `ELEVENLABS_API_KEY` - TTS (optional)
- `GITHUB_TOKEN` - GitHub operations (optional)

---

Add your own notes here as you discover environment-specific details.

**Note:** This is a template file safe for public repositories.
Update with your actual configuration after deployment.
