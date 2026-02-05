# Security Notice

## Token Rotation - February 5, 2026

**Issue:** Dashboard access token was accidentally committed to the public repository in commit `1ca2d01` (January 30, 2026).

**Exposed Token:** `***REMOVED-OLD-TOKEN***` (now **INVALID**)

**Actions Taken:**
1. ✅ New token generated: `***REMOVED-TOKEN***`
2. ✅ Container restarted with new token
3. ✅ Old token removed from `workspace-files/TOOLS.md`
4. ✅ Repository updated with placeholder text

**Status:** The exposed token is no longer valid. The dashboard is now secured with a new token.

**New Dashboard Access:**
- URL: ***REMOVED-URL***
- Token: Retrieve with `ssh ***REMOVED-VPS*** "sudo docker exec <container-name> openclaw config get gateway.auth.token"`

**Note:** Due to Windows limitations with git-filter-branch, the old token remains in git history but is **completely invalid** and cannot be used to access the system.

## Lessons Learned

1. Never commit tokens or secrets to the repository
2. Use placeholders in template files
3. Store secrets in environment variables or secure vaults
4. Rotate tokens immediately if exposed
