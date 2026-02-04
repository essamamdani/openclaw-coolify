# OpenClaw Setup Instructions

## 🎯 Implementation Status

### ✅ Automated (Already Done)
1. ✅ Dockerfile updated with Playwright (chromium browser automation)
2. ✅ Security configuration script created
3. ✅ Skills installation script created
4. ✅ Cron jobs setup script created
5. ✅ Post-bootstrap automation added

### ⚠️ Manual Steps Required

#### Step 1: Get Brave API Key (5 minutes)

**Why:** Enable web search for real-time information

1. Go to https://brave.com/search/api/
2. Click "Get Started" or "Sign Up"
3. Choose **"Data for Search"** plan (NOT "Data for AI")
4. Sign up with your email
5. In the dashboard, generate an API key
6. Copy the API key (looks like: `BSA...`)

**Free Tier:** 2,000 queries/month (plenty for personal use)

#### Step 2: Add API Key to Coolify

1. Open Coolify dashboard
2. Navigate to your OpenClaw project
3. Go to **"Environment Variables"** tab
4. Click **"Add Variable"**
5. Add:
   - **Name:** `BRAVE_API_KEY`
   - **Value:** `paste-your-api-key-here`
6. Click **"Save"**
7. **Restart** the deployment

#### Step 3: Push Changes to GitHub

```bash
# I'll do this for you
git add Dockerfile scripts/ SETUP-INSTRUCTIONS.md
git commit -m "feat: add Playwright, skills, cron jobs, and security config"
git push origin main
```

#### Step 4: Wait for Coolify Rebuild (5-10 minutes)

Coolify will automatically:
1. Detect the GitHub push
2. Pull latest code
3. Rebuild Docker image with Playwright
4. Start new container
5. Run post-bootstrap scripts

#### Step 5: Verify Installation

```bash
# Check container is running
ssh ***REMOVED-VPS*** "docker ps --filter name=openclaw"

# Check OpenClaw version
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw --version"

# Check installed skills
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw skills list"

# Check cron jobs
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw cron list"

# Test web search (after adding API key)
# Message your bot on Telegram: "Search for latest Docker security best practices"
```

---

## 📦 What Gets Installed

### 1. Playwright Browser Automation
- **Chromium browser** for web automation
- **Browser control** for screenshots, form filling, scraping
- **Headless mode** for server environments

### 2. Essential Skills
- **github** - GitHub CLI integration (repos, issues, PRs)
- **weather** - Weather forecasts (no API key needed)
- **summarize** - Summarize URLs, podcasts, videos
- **session-logs** - Search conversation history

### 3. Monitoring Cron Jobs
- **Daily Health Check** (2 AM) - Container status, memory, errors, sandboxes
- **Weekly Security Audit** (Sunday 3 AM) - Deep security scan
- **Daily Backup Reminder** (3 AM) - Check workspace backups

### 4. Exec Security Configuration
- **Allowlist mode** - Only approved commands can run
- **Approval system** - Dangerous commands require confirmation
- **Allowed commands:**
  - git, docker, npm, node, bun
  - openclaw, clawhub
  - curl, wget
  - ls, cat, grep, find
  - df, free, top, ps

---

## 🔍 Verification Checklist

After deployment completes:

- [ ] Container is running and healthy
- [ ] OpenClaw version is 2026.2.2-3
- [ ] Brave API key is set in environment
- [ ] 4 skills installed (github, weather, summarize, session-logs)
- [ ] 3 cron jobs created (health-check, security-audit, backup-reminder)
- [ ] Exec security configured (allowlist mode)
- [ ] Browser automation available (Playwright installed)
- [ ] Web search works (test via Telegram)

---

## 🧪 Testing

### Test Web Search
Message your bot on Telegram:
```
Search for latest Docker security best practices
```

Expected: Bot searches the web and provides current information with sources.

### Test Skills
```
What's the weather in Berlin?
```

Expected: Bot uses weather skill to provide forecast.

### Test Browser Automation
```
Take a screenshot of https://example.com
```

Expected: Bot uses browser to capture screenshot.

### Test Cron Jobs
```bash
# List cron jobs
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw cron list"

# Run health check manually
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw cron run --name daily-health-check"
```

### Test Exec Security
```
Run: git status
```

Expected: Command runs (in allowlist).

```
Run: rm -rf /
```

Expected: Blocked or requires approval (dangerous command).

---

## 🚨 Troubleshooting

### Web Search Not Working
**Symptom:** "Web search failed" or "API key not found"

**Solution:**
1. Verify `BRAVE_API_KEY` is set in Coolify environment variables
2. Restart deployment
3. Check logs: `docker logs <container-name> | grep -i brave`

### Skills Not Loading
**Symptom:** Skills show as "blocked" or not available

**Solution:**
1. Check skills directory: `docker exec <container-name> ls -la /root/openclaw-workspace/skills/`
2. Restart gateway: `docker exec <container-name> openclaw gateway restart`
3. Check logs: `docker logs <container-name> | grep -i skill`

### Browser Not Working
**Symptom:** "Browser disabled" or "Playwright not available"

**Solution:**
1. Verify Playwright is installed: `docker exec <container-name> playwright --version`
2. Check browser config: `docker exec <container-name> openclaw browser status`
3. Rebuild image if Playwright missing

### Cron Jobs Not Running
**Symptom:** No scheduled messages or alerts

**Solution:**
1. List jobs: `docker exec <container-name> openclaw cron list`
2. Check history: `docker exec <container-name> openclaw cron runs`
3. Test manually: `docker exec <container-name> openclaw cron run --name daily-health-check`

---

## 📚 Next Steps

After successful setup:

1. **Customize Cron Jobs** - Adjust schedules or add new jobs
2. **Install More Skills** - Browse https://clawhub.com for additional capabilities
3. **Configure WhatsApp** - Link WhatsApp Web for additional channel
4. **Create Custom Skills** - Build VPS-specific automation
5. **Set Up Webhooks** - Integrate with external services

---

## 🔗 Resources

- **OpenClaw Docs:** https://docs.openclaw.ai/
- **ClawHub (Skills):** https://clawhub.com
- **Brave Search API:** https://brave.com/search/api/
- **This Repo:** https://github.com/amraly83/openclaw-coolify

---

## 💡 Tips

- **Test incrementally** - Verify each feature works before moving to the next
- **Monitor logs** - Watch for errors during first run
- **Start simple** - Use basic commands before complex automation
- **Ask the bot** - OpenClaw can help troubleshoot itself!

---

**Need help?** Message your bot on Telegram or check the troubleshooting section above.
