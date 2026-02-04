# Skills Not Visible to Agent - Root Cause Analysis

## Issue Description

When asking the agent "what skills do you have?", it responds with "no skills" even though `openclaw skills list` shows 4 skills ready (github, weather, summarize, session-logs).

---

## Root Cause (From Official Documentation)

### Current Configuration

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",           // ← Every session runs in sandbox
        "workspaceAccess": "none", // ← Sandbox cannot see workspace
        "scope": "session"
      }
    }
  }
}
```

### The Problem

According to [OpenClaw Sandboxing Documentation](https://docs.openclaw.ai/gateway/sandboxing):

> **Skills note:** the `read` tool is sandbox-rooted. With `workspaceAccess: "none"`, OpenClaw mirrors eligible skills into the sandbox workspace (`.../skills`) so they can be read.

**What's happening:**
1. Agent runs in isolated sandbox container
2. Sandbox has `workspaceAccess: "none"` (cannot see `/root/openclaw-workspace/`)
3. Skills are in `/root/openclaw-workspace/skills/` (host workspace)
4. OpenClaw should mirror skills into sandbox workspace automatically
5. **Skills are NOT being mirrored** (verified: sandbox has no skills directory)

---

## Verification

### Host (Gateway) - Skills Present ✅
```bash
docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-103640351877 ls /root/openclaw-workspace/skills/
# Output: github  session-logs  summarize  weather
```

### Sandbox - Skills Missing ❌
```bash
docker exec openclaw-sbx-agent-main-telegram-dm-126471568-8d8f4917 ls /root/
# Output: No skills directory
```

---

## Official Solutions (From Documentation)

### Option 1: Enable Workspace Access (Recommended for VPS)

**Change:**
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "workspaceAccess": "ro",  // ← Read-only access to workspace
        "scope": "session"
      }
    }
  }
}
```

**Effect:**
- Sandbox mounts workspace at `/agent` (read-only)
- Skills at `/agent/skills/` become visible
- Agent can read workspace files but not modify them
- Disables `write`/`edit`/`apply_patch` tools

**Security:** Still secure - read-only mount, sandbox isolation maintained

---

### Option 2: Read-Write Access (Less Secure)

**Change:**
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "workspaceAccess": "rw",  // ← Full read-write access
        "scope": "session"
      }
    }
  }
}
```

**Effect:**
- Sandbox mounts workspace at `/workspace` (read-write)
- Skills at `/workspace/skills/` become visible
- Agent can read AND modify workspace files

**Security:** Less secure - agent can modify workspace files

---

### Option 3: Disable Sandboxing for Main Session

**Change:**
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",  // ← Only sandbox non-main sessions
        "workspaceAccess": "none",
        "scope": "session"
      }
    }
  }
}
```

**Effect:**
- Main session (direct chat) runs on host - sees all skills
- Group chats and external channels still sandboxed
- Skills work in main session

**Security:** Main session not sandboxed (less secure for main chat)

---

## Recommended Solution for Your VPS

Based on your security-focused setup and the official documentation:

### Use Option 1: Read-Only Workspace Access

**Why:**
1. ✅ Maintains sandbox isolation
2. ✅ Skills become visible to agent
3. ✅ Agent can read workspace files (useful for context)
4. ✅ Agent cannot modify workspace (security maintained)
5. ✅ Compatible with your current security setup

**Implementation:**

1. Update config via OpenClaw CLI:
```bash
docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-103640351877 \
  openclaw config set agents.defaults.sandbox.workspaceAccess "ro"
```

2. Restart gateway:
```bash
docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-103640351877 \
  openclaw gateway restart
```

3. Test:
Message bot on Telegram: "What skills do you have?"

---

## Alternative: Fix Skill Mirroring (If It Should Work)

According to the docs, skills should be mirrored automatically with `workspaceAccess: "none"`. If this isn't working, it might be a bug or configuration issue.

**To investigate:**
1. Check OpenClaw version for known issues
2. Check logs for skill mirroring errors
3. Try recreating sandbox: `openclaw sandbox recreate --agent main`

---

## Security Comparison

| Option | Sandbox | Skills Visible | Workspace Access | Security Level |
|--------|---------|----------------|------------------|----------------|
| Current (`none`) | ✅ Yes | ❌ No | None | 🔒🔒🔒 Highest |
| Option 1 (`ro`) | ✅ Yes | ✅ Yes | Read-only | 🔒🔒 High |
| Option 2 (`rw`) | ✅ Yes | ✅ Yes | Read-write | 🔒 Medium |
| Option 3 (`non-main`) | ⚠️ Partial | ✅ Yes (main) | Full (main) | 🔒 Medium |

---

## References

- [OpenClaw Sandboxing Documentation](https://docs.openclaw.ai/gateway/sandboxing)
- [OpenClaw Skills Documentation](https://docs.openclaw.ai/tools/skills)
- [OpenClaw Troubleshooting - Skill missing in sandbox](https://docs.openclaw.ai/gateway/troubleshooting#skill-missing-api-key-in-sandbox)
- [GitHub Issue: Skills are not visible](https://github.com/code-yeongyu/oh-my-opencode/issues/1039)

---

## Next Steps

1. **Review security requirements** - Decide if read-only workspace access is acceptable
2. **Apply configuration change** - Use Option 1 (recommended)
3. **Test skills** - Verify agent can see and use skills
4. **Monitor behavior** - Ensure no unexpected side effects

---

**Status:** Issue identified, official solution documented, awaiting user decision on which option to implement.
