# OpenClaw Tools - Complete Analysis & Recommendations

## Executive Summary

After deep-diving into OpenClaw's tool ecosystem, here's what you need to know for your VPS deployment:

**Current Status:**
- ✅ Core tools: Enabled and working
- ⚠️ Web tools: Partially configured (needs API keys)
- ❌ Skills: 0/49 installed (all blocked)
- ✅ Browser: Enabled but needs Playwright
- ✅ Exec: Sandboxed and secure

**Priority Actions:**
1. Configure web search (Brave API key)
2. Install essential skills (github, weather, summarize)
3. Set up cron jobs for monitoring
4. Configure exec approvals for security

---

## Tool Categories

### 1. Core Built-in Tools (Always Available)

#### **exec** - Shell Command Execution
**Purpose:** Run commands in the workspace or on host
**Status:** ✅ Enabled (sandboxed by default)
**Security:** Read-only filesystem, capability dropping, approval system

**Configuration Needed:**
```json
{
  "tools": {
    "exec": {
      "enabled": true,
      "security": "allowlist",  // Require approval for dangerous commands
      "ask": true,              // Ask before running
      "allowlist": [
        "/usr/bin/git",
        "/usr/bin/docker",
        "/usr/bin/npm",
        "/usr/local/bin/openclaw"
      ]
    }
  }
}
```

**Use Cases:**
- Git operations (status, commit, push)
- Docker management (ps, logs, stats)
- System monitoring (df, free, top)
- Package management (npm list, apt list)

**Recommendation:** ✅ **KEEP ENABLED** with allowlist security

---

#### **process** - Background Process Management
**Purpose:** Manage long-running commands (dev servers, watchers)
**Status:** ✅ Enabled
**Security:** Scoped per agent, automatic cleanup

**Use Cases:**
- Run development servers (npm run dev)
- Monitor logs (tail -f)
- Background tasks

**Recommendation:** ✅ **KEEP ENABLED**

---

#### **web_search** - Web Search
**Purpose:** Search the web using Brave or Perplexity
**Status:** ⚠️ Enabled but needs API key
**Providers:** Brave Search (default), Perplexity Sonar

**Configuration Needed:**
```bash
# Option 1: Brave Search (Recommended - Free tier available)
export BRAVE_API_KEY="your-key-here"

# Option 2: Perplexity via OpenRouter (AI-synthesized answers)
export OPENROUTER_API_KEY="your-key-here"
```

**Get Brave API Key:**
1. Go to https://brave.com/search/api/
2. Sign up for "Data for Search" plan (free tier available)
3. Generate API key
4. Add to Coolify environment variables

**Use Cases:**
- Real-time information lookup
- News and current events
- Technical documentation search
- Fact-checking

**Recommendation:** ✅ **CONFIGURE IMMEDIATELY** (Essential for AI assistant)

---

#### **web_fetch** - URL Content Extraction
**Purpose:** Fetch and extract readable content from URLs
**Status:** ✅ Enabled
**Features:** Readability extraction, Firecrawl support, caching

**Configuration:**
```json
{
  "tools": {
    "web": {
      "fetch": {
        "enabled": true,
        "maxChars": 50000,
        "timeoutSeconds": 30,
        "readability": true
      }
    }
  }
}
```

**Use Cases:**
- Read articles and documentation
- Extract content from web pages
- Summarize URLs
- Research and analysis

**Recommendation:** ✅ **KEEP ENABLED**

---

#### **browser** - Browser Automation
**Purpose:** Control a dedicated Chrome/Brave browser for automation
**Status:** ✅ Enabled but needs Playwright
**Features:** Snapshots, screenshots, UI actions, form filling

**Installation Needed:**
```dockerfile
# Add to Dockerfile
RUN playwright install chromium
```

**Configuration:**
```json
{
  "browser": {
    "enabled": true,
    "headless": true,
    "defaultProfile": "openclaw"
  }
}
```

**Use Cases:**
- Login to websites
- Fill forms
- Take screenshots
- Scrape dynamic content
- Test web applications

**Recommendation:** ✅ **INSTALL PLAYWRIGHT** (High value for automation)

---

#### **cron** - Scheduled Tasks
**Purpose:** Schedule recurring or one-time tasks
**Status:** ✅ Enabled
**Features:** Cron expressions, one-shot timers, delivery to channels

**Use Cases:**
- Daily health checks
- Scheduled backups
- Periodic monitoring
- Reminders and alerts

**Example Setup:**
```bash
# Daily health check at 2 AM
openclaw cron add \
  --name "health-check" \
  --schedule "0 2 * * *" \
  --message "Run health check and report any issues"

# Weekly security audit
openclaw cron add \
  --name "security-audit" \
  --schedule "0 3 * * 0" \
  --message "Run security audit and report findings"
```

**Recommendation:** ✅ **CONFIGURE MONITORING JOBS**

---

#### **message** - Multi-Channel Messaging
**Purpose:** Send messages across Telegram, Discord, Slack, WhatsApp, etc.
**Status:** ✅ Enabled (Telegram working)
**Channels:** Telegram ✅, WhatsApp ⚠️ (not linked), Discord, Slack, etc.

**Use Cases:**
- Send notifications
- Respond to messages
- Manage reactions
- Pin/unpin messages

**Recommendation:** ✅ **WORKING** (Consider adding WhatsApp)

---

#### **sessions** - Session Management
**Purpose:** List, inspect, and communicate between sessions
**Status:** ✅ Enabled
**Features:** Session history, cross-session messaging, spawning sub-agents

**Use Cases:**
- Review conversation history
- Spawn isolated tasks
- Multi-agent coordination

**Recommendation:** ✅ **KEEP ENABLED**

---

#### **memory** - Memory Search
**Purpose:** Search and retrieve from agent's memory
**Status:** ✅ Enabled (memory-core plugin)
**Features:** File-backed memory, vector search, FTS

**Use Cases:**
- Recall past conversations
- Search knowledge base
- Context retrieval

**Recommendation:** ✅ **KEEP ENABLED**

---

#### **canvas** - Visual Presentation
**Purpose:** Create visual presentations and UI
**Status:** ✅ Enabled
**Features:** Present content, eval code, snapshots

**Use Cases:**
- Data visualization
- Interactive demos
- UI prototyping

**Recommendation:** ✅ **KEEP ENABLED** (Low overhead)

---

#### **nodes** - Companion Devices
**Purpose:** Control paired devices (macOS, iOS, Android)
**Status:** ✅ Enabled (no nodes paired)
**Features:** Camera, screen recording, location, SMS

**Use Cases:**
- Remote device control
- Camera snapshots
- Screen recordings
- Location tracking

**Recommendation:** ⚠️ **OPTIONAL** (Only if you have companion devices)

---

#### **image** - Image Analysis
**Purpose:** Analyze images with AI vision models
**Status:** ✅ Enabled
**Features:** OCR, object detection, scene understanding

**Use Cases:**
- Screenshot analysis
- Document OCR
- Visual debugging

**Recommendation:** ✅ **KEEP ENABLED**

---

#### **gateway** - Gateway Management
**Purpose:** Restart or update the Gateway process
**Status:** ✅ Enabled
**Features:** In-place restart, update application

**Use Cases:**
- Apply configuration changes
- Restart after updates
- Troubleshooting

**Recommendation:** ✅ **KEEP ENABLED**

---

### 2. Skills (49 Available, 0 Installed)

Skills are installable capabilities that extend the agent. Currently **ALL BLOCKED**.

#### **Essential Skills to Install:**

##### 1. **github** - GitHub CLI Integration
**Purpose:** Manage GitHub repos, issues, PRs
**Installation:** `clawhub install github`
**Use Cases:**
- Check repo status
- Create issues
- Review PRs
- Manage releases

**Recommendation:** ✅ **INSTALL IMMEDIATELY**

---

##### 2. **weather** - Weather Information
**Purpose:** Get weather forecasts (no API key needed)
**Installation:** `clawhub install weather`
**Use Cases:**
- Current weather
- Forecasts
- Weather alerts

**Recommendation:** ✅ **INSTALL** (Useful for context)

---

##### 3. **summarize** - Content Summarization
**Purpose:** Summarize URLs, podcasts, videos
**Installation:** `clawhub install summarize`
**Use Cases:**
- Summarize articles
- Extract key points
- Transcribe videos

**Recommendation:** ✅ **INSTALL**

---

##### 4. **session-logs** - Conversation Analysis
**Purpose:** Search and analyze session logs
**Installation:** `clawhub install session-logs`
**Use Cases:**
- Search past conversations
- Analyze patterns
- Debug issues

**Recommendation:** ✅ **INSTALL**

---

##### 5. **himalaya** - Email Management
**Purpose:** IMAP/SMTP email client
**Installation:** `clawhub install himalaya`
**Use Cases:**
- Read emails
- Send emails
- Search inbox
- Manage folders

**Recommendation:** ⚠️ **OPTIONAL** (If you need email integration)

---

##### 6. **notion** - Notion Integration
**Purpose:** Manage Notion pages and databases
**Installation:** `clawhub install notion`
**Use Cases:**
- Create pages
- Update databases
- Search content

**Recommendation:** ⚠️ **OPTIONAL** (If you use Notion)

---

##### 7. **obsidian** - Obsidian Vault Management
**Purpose:** Work with Obsidian markdown notes
**Installation:** `clawhub install obsidian`
**Use Cases:**
- Create notes
- Search vault
- Link notes

**Recommendation:** ⚠️ **OPTIONAL** (If you use Obsidian)

---

##### 8. **trello** - Trello Board Management
**Purpose:** Manage Trello boards, lists, cards
**Installation:** `clawhub install trello`
**Use Cases:**
- Create cards
- Move tasks
- Update boards

**Recommendation:** ⚠️ **OPTIONAL** (If you use Trello)

---

#### **Skills for VPS Management:**

##### 9. **1password** - 1Password CLI
**Purpose:** Secure password management
**Installation:** `clawhub install 1password`
**Use Cases:**
- Retrieve secrets
- Inject credentials
- Secure storage

**Recommendation:** ⚠️ **OPTIONAL** (If you use 1Password)

---

##### 10. **tmux** - Terminal Multiplexer Control
**Purpose:** Control tmux sessions remotely
**Installation:** `clawhub install tmux`
**Use Cases:**
- Manage sessions
- Send keystrokes
- Scrape output

**Recommendation:** ⚠️ **OPTIONAL** (Advanced use case)

---

### 3. Plugin Tools (Optional Extensions)

#### **llm-task** - Structured LLM Tasks
**Purpose:** JSON-only LLM tool for workflows
**Status:** ⚠️ Disabled
**Use Cases:**
- Structured data extraction
- Workflow automation
- API integration

**Recommendation:** ⚠️ **OPTIONAL** (Advanced workflows)

---

#### **lobster** - Typed Workflow Tool
**Purpose:** Resumable workflows with approvals
**Status:** ⚠️ Disabled
**Use Cases:**
- Multi-step workflows
- Human-in-the-loop processes
- Complex automation

**Recommendation:** ⚠️ **OPTIONAL** (Advanced workflows)

---

#### **voice-call** - Voice Call Integration
**Purpose:** Start voice calls
**Status:** ⚠️ Disabled
**Use Cases:**
- Voice interactions
- Phone calls
- Audio communication

**Recommendation:** ❌ **NOT NEEDED** (VPS use case)

---

## Priority Configuration Plan

### Phase 1: Essential Setup (Do Now)

#### 1. Configure Web Search
```bash
# Get Brave API key from https://brave.com/search/api/
# Add to Coolify environment variables:
BRAVE_API_KEY=your-key-here
```

#### 2. Install Essential Skills
```bash
# SSH into container
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-064241424802 bash"

# Install skills
clawhub install github
clawhub install weather
clawhub install summarize
clawhub install session-logs

# Restart to load skills
exit
# Restart via Coolify dashboard
```

#### 3. Configure Exec Security
Add to `docker-compose.yaml` environment or Coolify env vars:
```yaml
OPENCLAW_EXEC_SECURITY: "allowlist"
OPENCLAW_EXEC_ASK: "true"
```

#### 4. Set Up Monitoring Cron Jobs
```bash
# Daily health check
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-064241424802 openclaw cron add --name health-check --schedule '0 2 * * *' --message 'Run health check: container status, memory usage, error logs, sandbox count. Report if issues found.'"

# Weekly security audit
ssh ***REMOVED-VPS*** "docker exec ***REMOVED-DEPLOYMENT-ID***-064241424802 openclaw cron add --name security-audit --schedule '0 3 * * 0' --message 'Run security audit --deep and report any warnings or critical issues.'"
```

---

### Phase 2: Enhanced Capabilities (Optional)

#### 1. Install Playwright for Browser Automation
Add to `Dockerfile`:
```dockerfile
# After the OpenClaw installation layer
RUN playwright install chromium chromium-deps
```

Rebuild and redeploy.

#### 2. Configure Additional Skills
Based on your needs:
- Email integration: `clawhub install himalaya`
- Note-taking: `clawhub install obsidian` or `clawhub install notion`
- Task management: `clawhub install trello`

#### 3. Set Up WhatsApp Channel
```bash
# Access dashboard
# Go to Channels → WhatsApp
# Scan QR code with phone
```

---

### Phase 3: Advanced Features (Future)

#### 1. Node Host Setup
If you want to run commands on a separate machine:
```bash
# On remote machine
openclaw node host --gateway ws://your-gateway:18789
```

#### 2. Custom Skills
Create custom skills for VPS-specific tasks:
```bash
mkdir -p skills/vps-management
cat > skills/vps-management/SKILL.md << 'EOF'
---
name: vps_management
description: VPS monitoring and management tasks
---

# VPS Management Skill

Monitor and manage the VPS:
- Check disk space
- Monitor Docker containers
- Review system logs
- Manage backups
EOF
```

#### 3. Advanced Automation
- Set up webhook triggers
- Configure email notifications
- Implement custom workflows

---

## Tool Policy Configuration

### Recommended Tool Policy

Create `.openclaw/openclaw.json` in the container workspace:

```json
{
  "tools": {
    "profile": "coding",
    "allow": [
      "exec",
      "process",
      "web_search",
      "web_fetch",
      "browser",
      "message",
      "cron",
      "sessions_list",
      "sessions_history",
      "memory_search",
      "image",
      "gateway"
    ],
    "deny": [],
    "exec": {
      "enabled": true,
      "security": "allowlist",
      "ask": true,
      "allowlist": [
        "/usr/bin/git",
        "/usr/bin/docker",
        "/usr/bin/npm",
        "/usr/bin/node",
        "/usr/local/bin/openclaw",
        "/usr/bin/curl",
        "/usr/bin/wget"
      ],
      "applyPatch": {
        "enabled": false
      }
    },
    "web": {
      "search": {
        "enabled": true,
        "provider": "brave",
        "count": 10
      },
      "fetch": {
        "enabled": true,
        "maxChars": 50000,
        "timeoutSeconds": 30
      }
    },
    "browser": {
      "enabled": true,
      "headless": true,
      "defaultProfile": "openclaw"
    },
    "elevated": {
      "enabled": false
    }
  },
  "skills": {
    "load": {
      "enabled": true,
      "bundled": true,
      "managed": true,
      "workspace": true
    }
  }
}
```

---

## Security Considerations

### Tool Security Matrix

| Tool | Risk Level | Mitigation | Recommendation |
|------|-----------|------------|----------------|
| exec | HIGH | Allowlist + approvals | ✅ Enable with security |
| process | MEDIUM | Scoped per agent | ✅ Enable |
| browser | MEDIUM | Isolated profile | ✅ Enable |
| web_search | LOW | API rate limits | ✅ Enable |
| web_fetch | LOW | Timeout + size limits | ✅ Enable |
| message | LOW | Channel auth | ✅ Enable |
| cron | MEDIUM | Isolated sessions | ✅ Enable |
| elevated | HIGH | Disabled by default | ❌ Keep disabled |
| gateway | MEDIUM | Restart only | ✅ Enable |

### Exec Approval Workflow

1. Agent requests command execution
2. If not in allowlist → approval required
3. Notification sent to Telegram
4. User approves/denies
5. Command executes or fails

**Configure approvals:**
```json
{
  "tools": {
    "exec": {
      "approvals": {
        "enabled": true,
        "timeoutSeconds": 300,
        "notifyChannel": "telegram"
      }
    }
  }
}
```

---

## Cost Considerations

### API Costs

| Service | Cost | Usage | Monthly Estimate |
|---------|------|-------|------------------|
| Brave Search | Free tier: 2,000 queries/month | ~10/day | $0 (free tier) |
| Anthropic Claude | $15/MTok input, $75/MTok output | Varies | $20-50/month |
| OpenRouter (Perplexity) | ~$0.001/query | Optional | $0-10/month |
| Firecrawl | Free tier: 500 pages/month | Optional | $0 (free tier) |

**Recommendation:** Start with free tiers, monitor usage, upgrade as needed.

---

## Implementation Checklist

### Immediate Actions (Today)

- [ ] Get Brave API key
- [ ] Add BRAVE_API_KEY to Coolify environment
- [ ] Restart deployment
- [ ] Install github skill
- [ ] Install weather skill
- [ ] Install summarize skill
- [ ] Test web search: "Search for latest Docker security best practices"
- [ ] Set up daily health check cron job
- [ ] Set up weekly security audit cron job

### Short-term (This Week)

- [ ] Add Playwright to Dockerfile
- [ ] Rebuild and redeploy
- [ ] Test browser automation
- [ ] Install session-logs skill
- [ ] Configure exec allowlist
- [ ] Test exec approvals workflow
- [ ] Document custom workflows

### Long-term (This Month)

- [ ] Set up WhatsApp channel
- [ ] Create custom VPS management skill
- [ ] Configure webhook triggers
- [ ] Set up backup automation
- [ ] Implement monitoring dashboards
- [ ] Optimize token usage

---

## Quick Start Commands

```bash
# Check current tool status
ssh ***REMOVED-VPS*** "docker exec <container> openclaw status --deep"

# Install a skill
ssh ***REMOVED-VPS*** "docker exec <container> clawhub install github"

# List installed skills
ssh ***REMOVED-VPS*** "docker exec <container> openclaw skills list"

# Add cron job
ssh ***REMOVED-VPS*** "docker exec <container> openclaw cron add --name test --schedule '*/5 * * * *' --message 'Test job'"

# List cron jobs
ssh ***REMOVED-VPS*** "docker exec <container> openclaw cron list"

# Test web search (after API key configured)
ssh ***REMOVED-VPS*** "docker exec <container> openclaw message send --channel telegram --target <your-id> --message 'Search for Docker security best practices'"
```

---

## Summary

**Must Configure:**
1. ✅ Brave API key for web search
2. ✅ Essential skills (github, weather, summarize)
3. ✅ Cron jobs for monitoring
4. ✅ Exec security (allowlist + approvals)

**Should Configure:**
5. ⚠️ Playwright for browser automation
6. ⚠️ Additional skills based on needs
7. ⚠️ WhatsApp channel

**Optional:**
8. ❌ Node hosts (if needed)
9. ❌ Custom skills
10. ❌ Advanced plugins

Your OpenClaw is already secure and functional. Adding web search and essential skills will make it significantly more capable for VPS management and general assistance tasks.
