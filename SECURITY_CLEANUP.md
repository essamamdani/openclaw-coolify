# Security Cleanup - February 12, 2026

## What Happened

This repository was public and contained sensitive information that should never be committed:

### Files Removed:
1. ✅ `scripts/test-authentication.sh` - Contained real passwords and tokens
2. ✅ `workspace-files/telegram_history.json` - Contained Telegram ID and conversation history

### Files Sanitized:
1. ✅ `workspace-files/USER.md` - Replaced real data with placeholders
2. ✅ `workspace-files/TOOLS.md` - Replaced real URLs and identifiers with placeholders

### .gitignore Updated:
Added patterns to prevent future commits of:
- Test authentication scripts
- Telegram history files
- Auth profile files
- Any history JSON files

## ⚠️ IMPORTANT: Credentials Still Need Rotation

The following credentials were exposed in git history and should be rotated:

### 1. HTTP Basic Auth Password
**Current:** `***REMOVED-PASSWORD***`
**Action Required:** Change in `docker-compose.yaml` and redeploy

```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update docker-compose.yaml with new htpasswd hash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$NEW_PASSWORD"
```

### 2. OpenClaw Gateway Token
**Current:** `***REMOVED-TOKEN***`
**Action Required:** Update in production config

```bash
# SSH into VPS
ssh ***REMOVED-VPS***

# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)

# Update openclaw.json (see AGENTS.md for safe procedure)
```

### 3. Old Token (Already Invalid)
**Old:** `***REMOVED-OLD-TOKEN***`
**Status:** Should already be invalid, but verify

## Git History Cleanup (Optional but Recommended)

The sensitive data is still in git history. To completely remove it:

### Option 1: BFG Repo-Cleaner (Recommended)
```bash
# Download BFG from https://rtyley.github.io/bfg-repo-cleaner/

# Clone fresh copy
git clone --mirror https://github.com/amraly83/openclaw-coolify.git

# Create passwords.txt with sensitive strings to remove
cat > passwords.txt << EOF
***REMOVED-TOKEN***
***REMOVED-OLD-TOKEN***
***REMOVED-PASSWORD***
***REMOVED-TELEGRAM-ID***
***REMOVED-USERNAME***
EOF

# Remove sensitive strings
java -jar bfg.jar --replace-text passwords.txt openclaw-coolify.git

# Clean up
cd openclaw-coolify.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (WARNING: This rewrites history!)
git push --force
```

### Option 2: Keep Current History
If you don't want to rewrite history:
- The old credentials are already in public git history
- Rotating them makes the exposed values useless
- Future commits won't contain sensitive data (thanks to .gitignore)

## Verification Checklist

After cleanup:

- [ ] Sensitive files removed from repository
- [ ] .gitignore updated to prevent future commits
- [ ] USER.md and TOOLS.md sanitized with placeholders
- [ ] HTTP Basic Auth password rotated
- [ ] OpenClaw gateway token rotated
- [ ] Old tokens verified as invalid
- [ ] Git history cleaned (optional)
- [ ] New credentials documented securely (NOT in repo)

## Going Forward

### Safe Practices:
✅ Use `.env` files for secrets (already gitignored)
✅ Use placeholders in committed files
✅ Review `git diff` before committing
✅ Never commit files from `/root/.openclaw/` on VPS
✅ Keep test scripts with real credentials local only

### Files Safe to Commit:
- Dockerfile
- docker-compose.yaml (without secrets)
- Scripts with placeholders
- Documentation with examples (not real values)
- .env.example (template only)

### Files NEVER to Commit:
- .env (real secrets)
- Test scripts with real credentials
- Telegram history exports
- Auth profile files
- Backup files from VPS
- Any file containing real tokens/passwords

## Resources

- Full remediation guide: `SECURITY_BREACH_REMEDIATION.md`
- Repository rules: `AGENTS.md` (section: Repository Cleanup Rules)
- BFG Repo-Cleaner: https://rtyley.github.io/bfg-repo-cleaner/

---

**Date:** February 12, 2026
**Status:** Files removed and sanitized, credentials rotation pending
**Next Action:** Rotate exposed credentials
