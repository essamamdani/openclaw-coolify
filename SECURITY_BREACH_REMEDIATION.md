# 🚨 SECURITY BREACH REMEDIATION PLAN

## CRITICAL: Your Public Repository Contains Sensitive Data

**Date Discovered:** 2026-02-11  
**Severity:** CRITICAL  
**Status:** REQUIRES IMMEDIATE ACTION

---

## 🔴 WHAT WAS EXPOSED

### Files Containing Sensitive Data:

1. **scripts/test-authentication.sh**
   - ❌ Real HTTP Basic Auth password: `***REMOVED-PASSWORD***`
   - ❌ Real OpenClaw token: `***REMOVED-TOKEN***`
   - ❌ Old token: `***REMOVED-OLD-TOKEN***`
   - ❌ Dashboard URL: `***REMOVED-URL***`

2. **workspace-files/USER.md**
   - ❌ Your Telegram ID: `***REMOVED-TELEGRAM-ID***`
   - ❌ Your Telegram username: `***REMOVED-USERNAME***`

3. **workspace-files/TOOLS.md**
   - ❌ Dashboard URL
   - ❌ Bot username: `***REMOVED-BOT***`

4. **workspace-files/telegram_history.json**
   - ❌ Your Telegram ID (repeated)
   - ❌ Old token in conversation history
   - ❌ Conversation transcripts

5. **AGENTS.md** (if committed)
   - ❌ May contain sensitive deployment info

---

## ⚡ IMMEDIATE ACTIONS (DO NOW)

### Step 1: Rotate All Credentials (URGENT)

#### 1.1 Change HTTP Basic Auth Password
```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "New password: $NEW_PASSWORD"

# Update docker-compose.yaml
# Change the htpasswd hash in traefik labels
docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$NEW_PASSWORD"

# Commit and push to trigger rebuild
```

#### 1.2 Rotate OpenClaw Gateway Token
```bash
# SSH into VPS
ssh ***REMOVED-VPS***

# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)
echo "New token: $NEW_TOKEN"

# Update openclaw.json
sudo docker exec <container> python3 << EOF
import json
config = json.load(open("/root/.openclaw/openclaw.json"))
config["gateway"]["auth"]["token"] = "$NEW_TOKEN"
json.dump(config, open("/root/.openclaw/openclaw.json", "w"), indent=2)
EOF

# Restart container
sudo docker restart <container>
```

#### 1.3 Update Telegram Bot (if compromised)
```bash
# If you suspect bot token is compromised, revoke it via @BotFather
# Create new bot or regenerate token
```

---

### Step 2: Remove Sensitive Files from Repository

#### 2.1 Delete Sensitive Files
```bash
# From your local machine
cd openclaw-coolify

# Remove files with sensitive data
git rm scripts/test-authentication.sh
git rm workspace-files/telegram_history.json
git rm workspace-files/USER.md  # Will recreate without sensitive data
git rm workspace-files/TOOLS.md  # Will recreate without sensitive data

# Commit removal
git commit -m "security: Remove files containing sensitive credentials"
```

#### 2.2 Update .gitignore
```bash
# Add to .gitignore
echo "workspace-files/telegram_history.json" >> .gitignore
echo "scripts/test-*.sh" >> .gitignore
echo "**/auth-profiles.json" >> .gitignore
echo "**/*history*.json" >> .gitignore

git add .gitignore
git commit -m "security: Update gitignore to prevent sensitive data commits"
```

---

### Step 3: Purge Git History (CRITICAL)

**WARNING:** Sensitive data is in git history. Anyone can see old commits!

#### Option A: Use BFG Repo-Cleaner (Recommended)
```bash
# Install BFG
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Clone a fresh copy
git clone --mirror https://github.com/amraly83/openclaw-coolify.git

# Remove sensitive strings
java -jar bfg.jar --replace-text passwords.txt openclaw-coolify.git

# passwords.txt contains:
# ***REMOVED-TOKEN***
# ***REMOVED-OLD-TOKEN***
# ***REMOVED-PASSWORD***
# ***REMOVED-TELEGRAM-ID***
# ***REMOVED-USERNAME***

# Clean up
cd openclaw-coolify.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push --force
```

#### Option B: Delete and Recreate Repository (Nuclear Option)
```bash
# 1. Create new empty repository on GitHub
# 2. Remove sensitive files locally
# 3. Push to new repository
# 4. Delete old repository
# 5. Update Coolify webhook to new repository
```

---

## 📋 WHAT TO DO GOING FORWARD

### 1. Never Commit These Files:

❌ **NEVER commit:**
- Files with real tokens/passwords
- Files with user IDs or personal info
- Conversation histories
- Auth profiles
- Credentials
- API keys
- Any file from `/root/.openclaw/` on VPS

✅ **SAFE to commit:**
- Dockerfile
- docker-compose.yaml (without secrets)
- Scripts (with placeholder values)
- Documentation (without real credentials)
- .env.example (template only)

---

### 2. Use Placeholders in Public Files

**BEFORE (WRONG):**
```bash
VALID_TOKEN="***REMOVED-TOKEN***"
BASIC_AUTH_PASS="***REMOVED-PASSWORD***"
```

**AFTER (CORRECT):**
```bash
VALID_TOKEN="${OPENCLAW_TOKEN:-your-token-here}"
BASIC_AUTH_PASS="${BASIC_AUTH_PASSWORD:-your-password-here}"
```

---

### 3. Use Environment Variables

**Create .env file (NOT committed):**
```bash
# .env (add to .gitignore)
OPENCLAW_TOKEN=***REMOVED-TOKEN***
BASIC_AUTH_PASSWORD=***REMOVED-PASSWORD***
TELEGRAM_USER_ID=***REMOVED-TELEGRAM-ID***
```

**Use in scripts:**
```bash
#!/bin/bash
source .env
VALID_TOKEN="${OPENCLAW_TOKEN}"
```

---

### 4. Review Before Every Commit

**Pre-commit checklist:**
```bash
# Check for secrets
git diff --cached | grep -i "token\|password\|secret\|key"

# Use detect-secrets
detect-secrets scan --baseline .secrets-baseline

# Review what you're committing
git diff --cached
```

---

## 🔒 SECURITY BEST PRACTICES

### For Public Repositories:

1. **Assume everything is public** - Because it is!
2. **Use templates** - Provide .example files with placeholders
3. **Document without exposing** - Explain without showing real values
4. **Separate secrets** - Keep sensitive data in .env files (gitignored)
5. **Review git history** - Old commits are still visible
6. **Use secret scanning** - Enable GitHub secret scanning
7. **Rotate regularly** - Change credentials periodically

### For Backup Scripts:

**The backup scripts are SAFE** because they:
- ✅ Don't contain hardcoded credentials
- ✅ Read from VPS volumes (not from repo)
- ✅ Store backups on VPS (not in repo)
- ✅ Use paths, not actual secrets

**But remember:**
- ❌ Never commit actual backup files (.tar.gz)
- ❌ Never commit files from `/root/openclaw-backups/`
- ❌ Never commit extracted backup contents

---

## 📊 DAMAGE ASSESSMENT

### What Was Exposed:
- ✅ Dashboard URL (public anyway, but now confirmed)
- ✅ HTTP Basic Auth credentials (can be changed)
- ✅ OpenClaw tokens (can be rotated)
- ✅ Your Telegram ID (public info, but privacy concern)
- ✅ Bot username (public anyway)

### What Was NOT Exposed:
- ✅ API keys (Anthropic, OpenAI, etc.) - stored in .env
- ✅ OAuth tokens (9 Google accounts) - stored in volumes
- ✅ Telegram bot token - stored in .env
- ✅ VPS SSH keys - never in repo
- ✅ Actual backup files - stored on VPS only

### Risk Level:
- **Current Risk:** HIGH (credentials exposed)
- **After Rotation:** LOW (old credentials invalidated)
- **Long-term Risk:** MEDIUM (git history still contains old secrets)

---

## ✅ REMEDIATION CHECKLIST

### Immediate (Do Today):
- [ ] Rotate HTTP Basic Auth password
- [ ] Rotate OpenClaw gateway token
- [ ] Remove sensitive files from repository
- [ ] Update .gitignore
- [ ] Commit and push changes

### Short-term (This Week):
- [ ] Purge git history (BFG or recreate repo)
- [ ] Enable GitHub secret scanning
- [ ] Review all committed files for sensitive data
- [ ] Create .env.example with placeholders
- [ ] Update documentation to use placeholders

### Long-term (Ongoing):
- [ ] Review commits before pushing
- [ ] Use pre-commit hooks for secret detection
- [ ] Rotate credentials quarterly
- [ ] Audit repository monthly
- [ ] Train on security best practices

---

## 📞 IF CREDENTIALS ARE COMPROMISED

### Signs of Compromise:
- Unauthorized access to dashboard
- Unexpected bot behavior
- Unknown messages sent by bot
- Unusual API usage
- Failed authentication attempts

### Response Plan:
1. **Immediately rotate all credentials**
2. **Check logs for unauthorized access**
3. **Review recent bot activity**
4. **Check API usage for anomalies**
5. **Enable 2FA where possible**
6. **Monitor for 48 hours**

---

## 📚 RESOURCES

- **GitHub Secret Scanning:** https://docs.github.com/en/code-security/secret-scanning
- **BFG Repo-Cleaner:** https://rtyley.github.io/bfg-repo-cleaner/
- **Git Filter-Repo:** https://github.com/newren/git-filter-repo
- **Detect Secrets:** https://github.com/Yelp/detect-secrets

---

**REMEMBER:** This is a PUBLIC repository. Treat it like anyone can see everything you commit!
