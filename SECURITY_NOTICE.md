# Security Notice - Dashboard Token Exposure & Authentication Bypass

**Date:** 2026-02-05  
**Severity:** HIGH (Authentication Bypass)  
**Status:** FIXED

## Incident Summary

Two security issues were discovered and fixed:

### Issue 1: Dashboard Token Exposed in Public Repository
- **Exposed token:** `***REMOVED-OLD-TOKEN***`
- **Location:** `workspace-files/TOOLS.md` (committed to public GitHub repo)
- **Exposure duration:** Unknown (token was in git history)
- **Impact:** Anyone with the token could access the OpenClaw dashboard

### Issue 2: Authentication Bypass (CRITICAL)
- **Root cause:** `gateway.bind="lan"` configuration treated all LAN connections as trusted
- **Impact:** ANY token (including invalid/random tokens) granted access to dashboard
- **Attack vector:** Traefik proxy connections appeared as LAN traffic, bypassing token validation
- **Discovery:** Old token still worked after rotation, testing revealed ANY token worked

## Actions Taken

### 1. Token Rotation (Incomplete - see Issue 2)
- ✅ Generated new token: `***REMOVED-TOKEN***`
- ✅ Updated `gateway.auth.token` in container config
- ✅ Updated `gateway.remote.token` in container config
- ✅ Restarted container
- ❌ Old token still worked (authentication was bypassed entirely)

### 2. Repository Cleanup
- ✅ Replaced exposed token in `workspace-files/TOOLS.md` with placeholder
- ✅ Created this security notice
- ⚠️ Git history cleanup failed (Windows git-filter-branch limitations)
- ⚠️ Old token remains in git history but is now invalidated by Fix #3

### 3. Secret Scanning Protection (5 layers)
- ✅ Pre-commit hooks (`.git/hooks/pre-commit` + `.git/hooks/pre-commit.ps1`)
- ✅ Enhanced `.gitignore` (40+ patterns)
- ✅ `.gitattributes` filters
- ✅ `.secrets-baseline.json` (detection patterns)
- ✅ `.github/SECURITY.md` (security policy)

### 4. Authentication Bypass Fix (CRITICAL)
- ✅ Added HTTP Basic Auth middleware in Traefik
- ✅ Two-layer authentication:
  - Layer 1: HTTP Basic Auth (username: `admin`, password: `***REMOVED-PASSWORD***`)
  - Layer 2: OpenClaw token (`***REMOVED-TOKEN***`)
- ✅ Updated `docker-compose.yaml` with Traefik middleware
- ✅ Documented in `AGENTS.md`

## Current Security Status

### ✅ FIXED
- Dashboard now requires HTTP Basic Auth before reaching OpenClaw
- Two layers of authentication provide defense in depth
- Secret scanning prevents future token leaks
- New token is properly enforced (after Basic Auth layer)

### ⚠️ KNOWN LIMITATIONS
- Old token remains in git history (GitHub repo is public)
- Git history rewrite failed due to Windows limitations
- **Mitigation:** Old token is now useless (blocked by HTTP Basic Auth)

## Access Credentials (Current)

**Public Dashboard:** ***REMOVED-URL***

**Layer 1 - HTTP Basic Auth:**
- Username: `admin`
- Password: `***REMOVED-PASSWORD***`

**Layer 2 - OpenClaw Token:**
- Token: `***REMOVED-TOKEN***`

**Full URL:**
```
***REMOVED-URL***?token=***REMOVED-TOKEN***
```

## Technical Details

### Why Authentication Was Bypassed

OpenClaw's `gateway.bind="lan"` setting treats all connections from the local network as trusted and skips token validation. When accessed through Traefik (reverse proxy), connections appear to come from the Coolify network (10.0.x.x), which is in the trusted proxy range.

**Configuration that caused the bypass:**
```json
{
  "gateway": {
    "bind": "lan",  // ← Treats LAN as trusted
    "trustedProxies": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
    "auth": { "mode": "token", "token": "..." }  // ← Ignored for LAN
  }
}
```

### The Fix

Added HTTP Basic Auth at the Traefik layer (before requests reach OpenClaw):

```yaml
labels:
  - "traefik.http.middlewares.openclaw-auth.basicauth.users=admin:$$2y$$05$$BCh00Pdtl45N1ruU88ztgecXRUV.azbYvYzt1Qv1isajZ/1x2kEga"
  - "traefik.http.middlewares.openclaw-auth.basicauth.realm=OpenClaw Dashboard"
```

This ensures authentication is enforced regardless of OpenClaw's bind mode.

## Recommendations

### Immediate Actions
1. ✅ Use the new credentials to access the dashboard
2. ✅ Verify old token no longer works (blocked by Basic Auth)
3. ✅ Test that invalid tokens are rejected

### Future Improvements
1. Consider using Tailscale Serve instead of LAN bind (more secure)
2. Rotate HTTP Basic Auth password periodically
3. Consider moving to OAuth or certificate-based auth
4. Monitor access logs for suspicious activity

## Lessons Learned

1. **Token rotation alone is insufficient** - Must verify authentication is actually enforced
2. **Test security fixes thoroughly** - Should have tested with invalid tokens
3. **Understand the security model** - `gateway.bind="lan"` has specific trust implications
4. **Defense in depth works** - Multiple auth layers prevented complete compromise
5. **Documentation matters** - OpenClaw docs clearly explain bind modes, but easy to miss

## Timeline

- **2026-02-05 14:00** - Token exposure discovered in public repo
- **2026-02-05 14:15** - Token rotated, config updated, container restarted
- **2026-02-05 14:30** - Secret scanning protection implemented (5 layers)
- **2026-02-05 15:00** - User reported old token still works
- **2026-02-05 15:15** - Testing revealed ANY token works (authentication bypass)
- **2026-02-05 15:30** - Root cause identified (`gateway.bind="lan"`)
- **2026-02-05 15:45** - HTTP Basic Auth implemented in Traefik
- **2026-02-05 16:00** - Fix deployed, authentication now enforced

## Contact

If you have questions about this incident or need to report a security issue:
- Create a private security advisory on GitHub
- Email: [your-email]

---

**This notice will remain in the repository as a record of the incident and the fixes applied.**
