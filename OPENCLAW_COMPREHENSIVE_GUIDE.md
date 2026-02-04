# OpenClaw Comprehensive Guide

**Version:** 2026.2.2-3  
**Last Updated:** February 4, 2026  
**Purpose:** Single source of truth for understanding OpenClaw architecture, configuration, and deployment

---

## Table of Contents

1. [Core Architecture](#core-architecture)
2. [Gateway System](#gateway-system)
3. [Agent Workspace](#agent-workspace)
4. [Skills System](#skills-system)
5. [Sandboxing](#sandboxing)
6. [Security Model](#security-model)
7. [Configuration](#configuration)
8. [Deployment Patterns](#deployment-patterns)
9. [Troubleshooting](#troubleshooting)

---

## Core Architecture

### What is OpenClaw?

OpenClaw is an **AI agent runtime orchestrator** that:
- Manages long-running AI agent processes
- Handles multi-channel communication (Telegram, Discord, Slack, etc.)
- Provides secure tool execution via sandboxing
- Maintains persistent sessions and memory
- Orchestrates Docker containers for isolated execution

**Key Principle:** OpenClaw is NOT a coding assistant. It's infrastructure for running AI agents.

### Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                     User Interfaces                      │
│  (Telegram, Discord, Slack, Web Dashboard, CLI)         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Gateway Process                        │
│  • WebSocket server (port 18789)                        │
│  • Single long-running Node.js process                  │
│  • Manages all agents, channels, sessions               │
│  • Routes messages between channels and agents          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Agent Instances                         │
│  • Each agent has its own workspace                     │
│  • Maintains session state and memory                   │
│  • Executes tools (file ops, shell, Docker)            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                 Sandbox Containers                       │
│  • Isolated Docker containers for tool execution        │
│  • Ephemeral or persistent based on scope               │
│  • Controlled via Docker Socket Proxy                   │
└─────────────────────────────────────────────────────────┘
```

### File System Layout

```
~/.openclaw/                          # OpenClaw home directory
├── openclaw.json                     # Main configuration file
├── gateway.lock                      # Gateway process lock file
├── agents/                           # Agent-specific configs
│   └── main/
│       ├── agent.json                # Agent configuration
│       └── sessions/                 # Session state files
│           └── <session-id>.json
├── channels/                         # Channel credentials
│   ├── telegram.json
│   ├── discord.json
│   └── slack.json
├── sandboxes/                        # Sandbox state (ephemeral)
│   └── <sandbox-id>/
│       ├── workspace/                # Sandbox workspace
│       └── skills/                   # Sandbox-specific skills
└── workspace/                        # Default agent workspace
    ├── AGENTS.md                     # Agent identity & rules
    ├── SOUL.md                       # Agent personality
    ├── USER.md                       # User information
    ├── TOOLS.md                      # Tool policies
    ├── HEARTBEAT.md                  # Monitoring checklist
    ├── MEMORY.md                     # Long-term memory
    ├── memory/                       # Daily logs
    │   └── YYYY-MM-DD.md
    └── skills/                       # Workspace skills
        └── <skill-name>/
            ├── SKILL.md              # Skill metadata
            └── scripts/              # Executable scripts
```

---

## Gateway System

### Gateway Process

The gateway is a **single long-running Node.js process** that:
- Listens on WebSocket port 18789
- Manages all agent lifecycles
- Routes messages between channels and agents
- Handles authentication and pairing
- Provides HTTP APIs (OpenAI-compatible, OpenResponses)

**Key Files:**
- `~/.openclaw/gateway.lock` - Prevents multiple gateway instances
- `~/.openclaw/openclaw.json` - Gateway configuration

### Gateway Configuration

Located at `~/.openclaw/openclaw.json`:

```json
{
  "gateway": {
    "port": 18789,
    "host": "0.0.0.0",
    "trustedProxies": ["10.0.1.0/24"],
    "mdnsMode": "minimal",
    "pairing": {
      "enabled": true,
      "allowlist": ["device-id-1", "device-id-2"]
    }
  },
  "agents": {
    "main": {
      "model": "anthropic:claude-sonnet-4",
      "workspace": "/root/openclaw-workspace",
      "systemPrompt": "file://AGENTS.md",
      "tools": {
        "exec": {
          "enabled": true,
          "requireApproval": true
        }
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "env:TELEGRAM_BOT_TOKEN"
    }
  },
  "sandbox": {
    "mode": "all",
    "defaultScope": "session",
    "workspaceAccess": "rw"
  }
}
```

### Gateway Commands

```bash
# Start gateway
openclaw gateway start

# Stop gateway
openclaw gateway stop

# Check status
openclaw status

# View logs
openclaw logs --follow

# Health check
openclaw health

# Security audit
openclaw security audit --deep
```

---

## Agent Workspace

### Workspace Structure

Each agent has a workspace directory (default: `~/.openclaw/workspace/`) containing:

**Configuration Files:**
- `AGENTS.md` - Agent identity, capabilities, and workspace rules
- `SOUL.md` - Agent personality and behavior patterns
- `USER.md` - User information and preferences
- `TOOLS.md` - Tool security policies and restrictions
- `HEARTBEAT.md` - Proactive monitoring checklist

**Memory Files:**
- `MEMORY.md` - Long-term curated memory (main session only)
- `memory/YYYY-MM-DD.md` - Daily raw logs and notes

**Skills Directory:**
- `skills/<skill-name>/` - Workspace-level skills (highest precedence)

### Agent Configuration Files

#### AGENTS.md
Defines agent identity and workspace rules. Auto-generated on first run.

**Key Sections:**
- Agent name and purpose
- Capabilities and limitations
- Workspace-specific rules
- Deployment information
- Common tasks and commands

#### SOUL.md
Defines agent personality and behavior. Auto-generated on first run.

**Key Sections:**
- Communication style
- Response patterns
- Proactive behaviors
- Error handling approach

#### TOOLS.md
Defines tool security policies and VPS-specific notes.

**Key Sections:**
- Exec approval requirements
- Allowed/blocked commands
- VPS details (SSH, container info)
- Security constraints

#### HEARTBEAT.md
Proactive monitoring checklist for the agent.

**Key Sections:**
- System health checks (frequency: 2-3 times per day)
- When to alert vs stay quiet
- Proactive tasks (memory review, workspace organization)

### Workspace Permissions

**Critical:** Workspace directory must be writable by the gateway process.

```bash
# Set correct ownership
chown -R openclaw:openclaw ~/.openclaw/workspace/

# Set correct permissions
chmod 755 ~/.openclaw/workspace/
chmod 644 ~/.openclaw/workspace/*.md
chmod 755 ~/.openclaw/workspace/skills/
```

---

## Skills System

### What are Skills?

Skills are **executable scripts** that extend agent capabilities. They can:
- Run shell commands
- Interact with APIs
- Process data
- Deploy applications
- Manage infrastructure

### Skill Precedence

Skills are loaded from multiple locations with this precedence (highest to lowest):

1. **Workspace skills** - `~/.openclaw/workspace/skills/`
2. **Managed skills** - `~/.openclaw/skills/` (installed via ClawHub)
3. **Bundled skills** - `/usr/local/lib/openclaw/skills/` (shipped with OpenClaw)

**Key Rule:** Workspace skills override managed skills, which override bundled skills.

### Skill Structure

```
skills/
└── skill-name/
    ├── SKILL.md              # Metadata and documentation
    └── scripts/              # Executable scripts
        ├── action1.sh
        ├── action2.py
        └── helper.js
```

### SKILL.md Format

```markdown
---
name: skill-name
description: Brief description of what this skill does
metadata:
  openclaw:
    emoji: 🔧
    requires:
      bins: ["curl", "jq"]
      env: ["API_KEY"]
---

# Skill Name

Detailed documentation about the skill.

## Usage

\`\`\`bash
skills/skill-name/scripts/action.sh "argument"
\`\`\`

## Scripts

- `action1.sh` - Does X
- `action2.py` - Does Y
```

**Critical:** All metadata must be inside the `---` delimiters!

### AgentSkills Format

Skills can also be defined in `AGENTS.md` using AgentSkills format:

```markdown
## Skills

### skill-name

**Description:** Brief description

**Scripts:**
- `action.sh` - Does X

**Usage:**
\`\`\`bash
skills/skill-name/scripts/action.sh "argument"
\`\`\`
```

### Installing Skills

**Method 1: Repository-based (Recommended for Production)**
```bash
# Add skill to repository
mkdir -p skills/skill-name/scripts
echo "#!/bin/bash" > skills/skill-name/scripts/action.sh
chmod +x skills/skill-name/scripts/action.sh

# Create SKILL.md
cat > skills/skill-name/SKILL.md << 'EOF'
---
name: skill-name
description: Skill description
---
# Skill Documentation
EOF

# Commit and deploy
git add skills/
git commit -m "Add skill-name skill"
git push origin main
```

**Method 2: ClawHub (Runtime Installation)**
```bash
# Search for skills
openclaw skills search "keyword"

# Install skill
openclaw skills install github/skill-name

# List installed skills
openclaw skills list
```

**Warning:** ClawHub skills installed at runtime don't persist across container restarts in Docker deployments. Use repository-based skills for production.

---

## Sandboxing

### Sandbox Modes

OpenClaw supports three sandbox modes:

1. **off** - No sandboxing (tools run in gateway process)
2. **non-main** - Sandbox only non-main agents (main agent runs in gateway)
3. **all** - Sandbox all agents (recommended for production)

**Configuration:**
```json
{
  "sandbox": {
    "mode": "all"
  }
}
```

### Sandbox Scopes

Sandboxes can have different lifecycles:

1. **session** - One sandbox per session (ephemeral, destroyed after session ends)
2. **agent** - One sandbox per agent (persistent across sessions)
3. **shared** - One sandbox shared by all agents (persistent)

**Configuration:**
```json
{
  "sandbox": {
    "defaultScope": "session"
  }
}
```

### Workspace Access

Sandboxes can have different levels of workspace access:

1. **none** - No workspace access (isolated)
2. **ro** - Read-only workspace access
3. **rw** - Read-write workspace access (default)

**Configuration:**
```json
{
  "sandbox": {
    "workspaceAccess": "rw"
  }
}
```

### Sandbox Container Naming

Sandbox containers follow this naming pattern:

```
openclaw-sbx-<agent-name>-<scope>-<session-id>-<timestamp>
```

**Examples:**
- `openclaw-sbx-agent-main-main-session-abc123-1234567890`
- `openclaw-sbx-agent-main-telegram-dm-user123-1234567890`
- `openclaw-sbx-agent-main-subagent-task456-1234567890`

### Sandbox Lifecycle

**Session-scoped sandboxes:**
1. Created when session starts
2. Workspace mounted (if `workspaceAccess` is `ro` or `rw`)
3. Tools executed inside sandbox
4. Destroyed when session ends

**Agent-scoped sandboxes:**
1. Created on first use
2. Reused across sessions
3. Persists until manually destroyed or gateway restart

### Managing Sandboxes

```bash
# List running sandboxes
docker ps --filter name=openclaw-sbx

# View sandbox logs
docker logs openclaw-sbx-<name>

# Execute command in sandbox
docker exec openclaw-sbx-<name> <command>

# Stop sandbox
docker stop openclaw-sbx-<name>

# Remove sandbox
docker rm openclaw-sbx-<name>

# Clean up stopped sandboxes
docker container prune -f --filter label=openclaw.sandbox=true
```

---

## Security Model

### Pairing System

OpenClaw uses a **pairing system** to authenticate devices:

1. Device requests pairing code
2. User approves pairing on gateway
3. Device receives authentication token
4. Token used for all future requests

**Configuration:**
```json
{
  "gateway": {
    "pairing": {
      "enabled": true,
      "allowlist": ["device-id-1", "device-id-2"]
    }
  }
}
```

**Commands:**
```bash
# List paired devices
openclaw pairing list

# Approve pairing request
openclaw pairing approve <device-id>

# Revoke device
openclaw pairing revoke <device-id>
```

### Tool Policies

Tools can have different security policies:

**Exec Tool:**
```json
{
  "agents": {
    "main": {
      "tools": {
        "exec": {
          "enabled": true,
          "requireApproval": true,
          "allowlist": ["ls", "cat", "grep"],
          "blocklist": ["rm -rf", "dd if="]
        }
      }
    }
  }
}
```

**File Tool:**
```json
{
  "agents": {
    "main": {
      "tools": {
        "file": {
          "enabled": true,
          "allowedPaths": ["/root/openclaw-workspace"],
          "blockedPaths": ["/etc", "/root/.ssh"]
        }
      }
    }
  }
}
```

### Security Best Practices

1. **Always use sandboxing** - Set `sandbox.mode` to `all`
2. **Require exec approval** - Set `tools.exec.requireApproval` to `true`
3. **Use allowlists** - Restrict pairing to known devices
4. **Limit workspace access** - Use `ro` for read-only tasks
5. **Drop capabilities** - Use Docker `cap_drop: ALL`
6. **Read-only filesystem** - Use Docker `read_only: true`
7. **Use Docker socket proxy** - Never mount `/var/run/docker.sock` directly
8. **Restrict trusted proxies** - Don't use `*` for `trustedProxies`
9. **Disable mDNS** - Set `mdnsMode` to `minimal` or `off`
10. **Rotate API keys** - Regularly rotate all API keys

### Prompt Injection Risks

**Warning:** AI agents are vulnerable to prompt injection attacks. Always:
- Validate user input
- Sanitize file contents before processing
- Use tool policies to restrict dangerous operations
- Monitor agent behavior for anomalies
- Review logs regularly

---

## Configuration

### Configuration File Location

**Primary:** `~/.openclaw/openclaw.json`

**Environment Variables:**
- `OPENCLAW_CONFIG` - Override config file location
- `OPENCLAW_HOME` - Override home directory (default: `~/.openclaw`)
- `OPENCLAW_WORKSPACE` - Override workspace directory

### Configuration Schema

```json
{
  "gateway": {
    "port": 18789,
    "host": "0.0.0.0",
    "trustedProxies": ["10.0.1.0/24"],
    "mdnsMode": "minimal",
    "pairing": {
      "enabled": true,
      "allowlist": []
    }
  },
  "agents": {
    "<agent-name>": {
      "model": "anthropic:claude-sonnet-4",
      "workspace": "/root/openclaw-workspace",
      "systemPrompt": "file://AGENTS.md",
      "tools": {
        "exec": {
          "enabled": true,
          "requireApproval": true,
          "allowlist": [],
          "blocklist": []
        },
        "file": {
          "enabled": true,
          "allowedPaths": [],
          "blockedPaths": []
        }
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "env:TELEGRAM_BOT_TOKEN"
    },
    "discord": {
      "enabled": false,
      "token": "env:DISCORD_BOT_TOKEN"
    }
  },
  "sandbox": {
    "mode": "all",
    "defaultScope": "session",
    "workspaceAccess": "rw",
    "image": "openclaw-sandbox:bookworm-slim"
  },
  "models": {
    "anthropic:claude-sonnet-4": {
      "provider": "anthropic",
      "apiKey": "env:ANTHROPIC_API_KEY"
    }
  }
}
```

### Environment Variable References

Use `env:VAR_NAME` to reference environment variables:

```json
{
  "channels": {
    "telegram": {
      "token": "env:TELEGRAM_BOT_TOKEN"
    }
  }
}
```

**Supported formats:**
- `env:VAR_NAME` - Required variable (fails if not set)
- `env:VAR_NAME:default` - Optional variable with default value

### Configuration Commands

```bash
# View current configuration
openclaw config get

# Set configuration value
openclaw config set gateway.port 18789

# Validate configuration
openclaw config validate

# Reset to defaults
openclaw config reset
```

---

## Deployment Patterns

### Docker Deployment (Recommended)

**Dockerfile:**
```dockerfile
FROM node:22-bookworm

# Install OpenClaw
RUN npm install -g openclaw@2026.2.2-3

# Copy configuration
COPY openclaw.json /root/.openclaw/
COPY workspace/ /root/openclaw-workspace/

# Expose gateway port
EXPOSE 18789

# Start gateway
CMD ["openclaw", "gateway", "start"]
```

**docker-compose.yaml:**
```yaml
version: '3.8'

services:
  openclaw:
    build: .
    ports:
      - "18789:18789"
    volumes:
      - openclaw-config:/root/.openclaw
      - openclaw-workspace:/root/openclaw-workspace
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
    read_only: true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp:size=200M,noexec
      - /var/tmp:size=100M,noexec
      - /run:size=50M

  docker-proxy:
    image: tecnativa/docker-socket-proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - POST=1
      - CONTAINERS=1
      - IMAGES=1
      - NETWORKS=1
      - EXEC=1
      - EVENTS=1

volumes:
  openclaw-config:
  openclaw-workspace:
```

### VPS Deployment

**Requirements:**
- Ubuntu 22.04+ or Debian 12+
- Docker 24.0+
- 2GB RAM minimum (4GB recommended)
- 10GB disk space

**Installation:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone repository
git clone https://github.com/user/openclaw-deployment.git
cd openclaw-deployment

# Configure environment
cp .env.example .env
nano .env  # Add API keys

# Deploy
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f openclaw
```

### Coolify Deployment

**Setup:**
1. Add GitHub repository to Coolify
2. Configure webhook for automatic deployments
3. Set environment variables in Coolify dashboard
4. Deploy

**Webhook Workflow:**
```
Local Changes → Git Push → GitHub Webhook → Coolify Rebuild → Auto Deploy
```

**Key Points:**
- Never edit files directly on VPS
- All changes must go through Git
- Coolify handles build and deployment automatically

---

## Troubleshooting

### Gateway Won't Start

**Symptom:** `openclaw gateway start` fails

**Possible Causes:**
1. Port 18789 already in use
2. Configuration file invalid
3. Missing API keys
4. Permissions issue

**Solutions:**
```bash
# Check if port is in use
lsof -i :18789

# Validate configuration
openclaw config validate

# Check environment variables
env | grep -E '(ANTHROPIC|OPENAI|TELEGRAM)'

# Check permissions
ls -la ~/.openclaw/
```

### Skills Not Showing Up

**Symptom:** Agent reports "No external skills installed"

**Possible Causes:**
1. Skills not in workspace directory
2. SKILL.md frontmatter malformed
3. Scripts not executable
4. Workspace not mounted in sandbox

**Solutions:**
```bash
# Check skills directory
ls -la ~/.openclaw/workspace/skills/

# Verify SKILL.md format
cat ~/.openclaw/workspace/skills/*/SKILL.md

# Make scripts executable
find ~/.openclaw/workspace/skills -type f -name "*.sh" -exec chmod +x {} \;

# Check sandbox workspace access
openclaw config get sandbox.workspaceAccess
```

### Sandbox Containers Accumulating

**Symptom:** Many stopped sandbox containers

**Solution:**
```bash
# List stopped sandboxes
docker ps -a --filter name=openclaw-sbx --filter status=exited

# Clean up
docker container prune -f --filter label=openclaw.sandbox=true
```

### Memory Issues

**Symptom:** High memory usage or OOM errors

**Solutions:**
```bash
# Check memory usage
docker stats --no-stream

# Review session count
openclaw sessions list

# Prune old sessions
openclaw sessions prune --older-than 7d

# Increase memory limit in docker-compose.yaml
```

### Read-Only Filesystem Errors

**Symptom:** "Read-only file system" errors in logs

**Expected Behavior:** Container has read-only root filesystem for security.

**Writable Locations:**
- `/tmp` (tmpfs)
- `/var/tmp` (tmpfs)
- `/root/.openclaw` (volume)
- `/root/openclaw-workspace` (volume)

**Solution:** Ensure application writes only to these locations.

### Docker Build Failures

**Symptom:** Build fails with "file not found" errors

**Possible Causes:**
1. `.dockerignore` excluding required files
2. Files not tracked by Git
3. Incorrect COPY paths in Dockerfile

**Solutions:**
```bash
# Check .dockerignore
cat .dockerignore

# Verify file is tracked
git ls-files <filename>

# Test build locally
docker-compose build
```

---

## Quick Reference

### Essential Commands

```bash
# Gateway
openclaw gateway start
openclaw gateway stop
openclaw status
openclaw health

# Configuration
openclaw config get
openclaw config set <key> <value>
openclaw config validate

# Skills
openclaw skills list
openclaw skills install <name>
openclaw skills search <query>

# Sessions
openclaw sessions list
openclaw sessions prune --older-than 7d

# Channels
openclaw channels list
openclaw channels status

# Security
openclaw security audit --deep
openclaw pairing list

# Logs
openclaw logs --follow
openclaw logs --level error
```

### File Locations

```
~/.openclaw/openclaw.json          # Main configuration
~/.openclaw/workspace/AGENTS.md    # Agent identity
~/.openclaw/workspace/SOUL.md      # Agent personality
~/.openclaw/workspace/TOOLS.md     # Tool policies
~/.openclaw/workspace/skills/      # Workspace skills
~/.openclaw/agents/                # Agent configs
~/.openclaw/channels/              # Channel credentials
```

### Environment Variables

```bash
ANTHROPIC_API_KEY          # Anthropic API key
OPENAI_API_KEY             # OpenAI API key
TELEGRAM_BOT_TOKEN         # Telegram bot token
OPENCLAW_CONFIG            # Config file location
OPENCLAW_HOME              # Home directory
OPENCLAW_WORKSPACE         # Workspace directory
```

---

## Resources

- **Official Docs:** https://docs.openclaw.ai/
- **GitHub:** https://github.com/openclaw/openclaw
- **Security Guide:** https://docs.openclaw.ai/gateway/security/
- **Skills Repository:** https://clawhub.ai/

---

**Last Updated:** February 4, 2026  
**Guide Version:** 1.0.0
