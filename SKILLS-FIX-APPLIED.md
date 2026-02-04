# ✅ Skills Visibility Fix Applied

**Date:** February 4, 2026  
**Container:** openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494  
**Status:** Configuration updated and applied

---

## What Was Changed

### Configuration Update

**Before:**
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "workspaceAccess": "none",  // ← Sandbox couldn't see workspace
        "scope": "session"
      }
    }
  }
}
```

**After:**
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "workspaceAccess": "ro",  // ← Sandbox now has read-only access
        "scope": "session"
      }
    }
  }
}
```

### Commands Executed

```bash
# 1. Update configuration
docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw config set agents.defaults.sandbox.workspaceAccess 'ro'
# Output: Updated agents.defaults.sandbox.workspaceAccess. Restart the gateway to apply.

# 2. Restart container to apply changes
docker restart openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494

# 3. Verify configuration
docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw config get agents.defaults.sandbox.workspaceAccess
# Output: ro ✅
```

---

## What This Means

### For the Agent

**Before:**
- Agent ran in isolated sandbox
- Could NOT see workspace files
- Could NOT see skills in `/root/openclaw-workspace/skills/`
- Responded "no skills" when asked

**After:**
- Agent still runs in isolated sandbox (security maintained)
- CAN see workspace files (read-only)
- CAN see skills at `/agent/skills/`
- Should now list available skills when asked

### For Security

**Security Level:** Still High 🔒🔒

- ✅ Sandbox isolation maintained
- ✅ Read-only access (agent cannot modify workspace)
- ✅ All capabilities dropped
- ✅ Read-only root filesystem
- ✅ Resource limits enforced
- ⚠️ Agent can read workspace files (but not modify)

**What agent can now do:**
- Read files in workspace (useful for context)
- See and use skills
- Read memory files, AGENTS.md, SOUL.md, etc.

**What agent still CANNOT do:**
- Modify workspace files
- Delete files
- Create new files in workspace
- Escape sandbox

---

## Testing Instructions

### Test 1: Ask About Skills

Message your bot on Telegram:
```
What skills do you have?
```

**Expected Response:**
Agent should list the 4 available skills:
- 🐙 github - GitHub CLI integration
- 🌤️ weather - Weather forecasts
- 🧾 summarize - Content summarization
- 📜 session-logs - Conversation search

**If it still says "no skills":**
- Wait for a new sandbox to be created (happens on next message)
- Old sandbox containers may still have old config

---

### Test 2: Use a Skill

Message your bot on Telegram:
```
What's the weather in Berlin?
```

**Expected Response:**
Agent should use the weather skill to provide current weather and forecast.

---

### Test 3: Use GitHub Skill

Message your bot on Telegram:
```
Show me my GitHub repositories
```

**Expected Response:**
Agent should use the github skill (gh CLI) to list your repositories.

---

### Test 4: Summarize Skill

Message your bot on Telegram:
```
Summarize https://docs.openclaw.ai/
```

**Expected Response:**
Agent should fetch and summarize the page content.

---

## Verification Commands

### Check Configuration
```bash
ssh netcup "docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw config get agents.defaults.sandbox.workspaceAccess"
# Expected: ro
```

### Check Skills List
```bash
ssh netcup "docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw skills list"
# Expected: Skills (4/50 ready)
```

### Check Sandbox Mounts (After New Sandbox Created)
```bash
# Find new sandbox container
ssh netcup "docker ps --format '{{.Names}}' | grep sbx"

# Check if workspace is mounted
ssh netcup "docker inspect <sandbox-container-name> --format '{{json .Mounts}}'"
# Expected: Should show mount from openclaw-workspace to /agent (ro)
```

---

## Troubleshooting

### If Agent Still Says "No Skills"

**Reason:** Old sandbox container may still be running with old config.

**Solution 1: Wait for New Sandbox**
- Send a new message to the bot
- OpenClaw will create a new sandbox with the new config
- Old sandbox will be cleaned up automatically

**Solution 2: Recreate Sandbox Manually**
```bash
ssh netcup "docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw sandbox recreate --agent main"
```

**Solution 3: Stop Old Sandbox**
```bash
# Find old sandbox
ssh netcup "docker ps -a | grep sbx"

# Stop and remove old sandbox
ssh netcup "docker stop <old-sandbox-name>"
ssh netcup "docker rm <old-sandbox-name>"

# New sandbox will be created on next message
```

---

### If Skills Work But Agent Can't Read Workspace Files

**This is expected!** The agent can now read workspace files, but:
- Files must be in `/root/openclaw-workspace/`
- Agent sees them at `/agent/` (read-only mount)
- Agent cannot modify them

**Example:**
```
Message: "Read the file AGENTS.md"
Agent sees: /agent/AGENTS.md (read-only)
```

---

## Rollback Instructions

If you need to revert to the previous configuration:

```bash
# Revert to no workspace access
ssh netcup "docker exec openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494 \
  openclaw config set agents.defaults.sandbox.workspaceAccess 'none'"

# Restart container
ssh netcup "docker restart openclaw-qsw0sgsgwcog4wg88g448sgs-111025847494"
```

**Note:** This will make skills invisible again.

---

## Persistence

### Is This Change Permanent?

**Yes!** The configuration is stored in the persistent Docker volume:
- Volume: `qsw0sgsgwcog4wg88g448sgs_openclaw-config`
- File: `/root/.openclaw/openclaw.json`
- Survives: Container recreation, image updates, restarts

### Will It Survive Future Deployments?

**Yes!** Because:
1. Configuration is in Docker volume (not container filesystem)
2. Volumes persist across container recreations
3. Coolify mounts the same volumes to new containers

**However:** If you manually edit `openclaw.json` in the repository and push to GitHub, it will override this change. Don't commit config changes to Git unless intentional.

---

## Next Steps

1. ✅ Configuration applied
2. ⏳ Test with Telegram bot (send message asking about skills)
3. ⏳ Verify skills are visible and working
4. ⏳ Test each skill (weather, github, summarize, session-logs)
5. ✅ Monitor for any issues

---

## Summary

**What was done:**
- Changed `workspaceAccess` from `"none"` to `"ro"`
- Restarted gateway to apply changes
- Configuration saved to persistent volume

**Expected result:**
- Agent can now see and use skills
- Agent can read workspace files (read-only)
- Security still maintained (sandbox + read-only)

**Test it:**
Message bot on Telegram: "What skills do you have?"

---

**Status:** ✅ Fix applied, awaiting user testing
