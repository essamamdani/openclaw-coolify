# OpenClaw Configuration Implementation Guide

## Step-by-Step Implementation

### 1. Configure Web Search (Brave API) ⚠️ REQUIRES USER ACTION

**You need to get a Brave API key:**

1. Go to https://brave.com/search/api/
2. Click "Get Started" or "Sign Up"
3. Choose the "Data for Search" plan (NOT "Data for AI")
4. Sign up with your email
5. Generate an API key from the dashboard
6. Copy the API key

**Then add it to Coolify:**

1. Open Coolify dashboard
2. Go to your OpenClaw project
3. Navigate to "Environment Variables"
4. Add new variable:
   - Name: `BRAVE_API_KEY`
   - Value: `your-api-key-here`
5. Save and restart the deployment

**Alternative: Add to .env file locally (not recommended for secrets):**
```bash
# Add to .env file
BRAVE_API_KEY=your-api-key-here
```

**Verify it works:**
```bash
ssh ***REMOVED-VPS*** "docker exec <container-name> openclaw message send --channel telegram --target <your-id> --message 'Search for latest Docker security best practices'"
```

---

### 2. Install Essential Skills ✅ AUTOMATED

I'll create a script to install these skills automatically.

---

### 3. Set Up Monitoring Cron Jobs ✅ AUTOMATED

I'll create cron jobs for health checks and security audits.

---

### 4. Configure Exec Security ✅ AUTOMATED

I'll add exec security configuration to the deployment.

---

### 5. Add Playwright for Browser Automation ✅ AUTOMATED

I'll update the Dockerfile to include Playwright.

---

## Automated Implementation

The following changes will be made automatically:
- Dockerfile updated with Playwright
- Skills installation script created
- Cron jobs configuration script created
- Exec security configuration added

**After I make these changes, you need to:**
1. Get Brave API key (manual step)
2. Add it to Coolify environment variables
3. Push changes to GitHub (I'll do this)
4. Wait for Coolify to rebuild (automatic)
5. Verify everything works
