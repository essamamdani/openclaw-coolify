# Master Security Remediation Script
# This script orchestrates the complete security cleanup process

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         OPENCLAW SECURITY REMEDIATION SCRIPT               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Clean git history (remove sensitive files and strings)" -ForegroundColor White
Write-Host "  2. Generate new credentials" -ForegroundColor White
Write-Host "  3. Provide instructions for deployment" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  WARNING: This will rewrite git history!" -ForegroundColor Red
Write-Host "⚠️  Make sure you have committed all current changes first!" -ForegroundColor Red
Write-Host ""

$Confirm = Read-Host "Do you want to continue? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 1: COMMIT CURRENT CHANGES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if there are uncommitted changes
$Status = git status --porcelain
if ($Status) {
    Write-Host "Uncommitted changes detected. Committing..." -ForegroundColor Yellow
    
    git add .gitignore workspace-files/USER.md workspace-files/TOOLS.md SECURITY_CLEANUP.md
    git rm --cached scripts/test-authentication.sh 2>$null
    git rm --cached workspace-files/telegram_history.json 2>$null
    
    git commit -m "security: Remove sensitive files and sanitize workspace templates

- Remove test-authentication.sh (contained real passwords/tokens)
- Remove telegram_history.json (contained Telegram ID and history)
- Sanitize USER.md and TOOLS.md with placeholders
- Update .gitignore to prevent future sensitive commits
- Add SECURITY_CLEANUP.md documenting the cleanup

See SECURITY_CLEANUP.md for credential rotation instructions."
    
    Write-Host "✅ Changes committed" -ForegroundColor Green
} else {
    Write-Host "✅ No uncommitted changes" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 2: CLEAN GIT HISTORY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if git-filter-repo is installed
try {
    python -m git_filter_repo --version 2>&1 | Out-Null
    Write-Host "✅ git-filter-repo is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ git-filter-repo not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installing git-filter-repo..." -ForegroundColor Yellow
    pip install git-filter-repo
    Write-Host "✅ git-filter-repo installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Running git history cleanup..." -ForegroundColor Yellow
& "$PSScriptRoot\clean-git-history.ps1"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 3: GENERATE NEW CREDENTIALS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

& "$PSScriptRoot\rotate-credentials.ps1"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PHASE 4: FINAL STEPS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Security remediation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Review the changes:" -ForegroundColor White
Write-Host "   git log --oneline -10" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Update docker-compose.yaml with new htpasswd hash" -ForegroundColor White
Write-Host "   (See new-credentials-*.txt file)" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Commit the docker-compose.yaml change:" -ForegroundColor White
Write-Host "   git add docker-compose.yaml" -ForegroundColor Cyan
Write-Host "   git commit -m 'security: Rotate HTTP Basic Auth password'" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Force push to GitHub (⚠️  REWRITES HISTORY):" -ForegroundColor White
Write-Host "   git push origin main --force" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. SSH into VPS and update OpenClaw token:" -ForegroundColor White
Write-Host "   (Instructions in new-credentials-*.txt file)" -ForegroundColor Cyan
Write-Host ""
Write-Host "6. Test access with new credentials" -ForegroundColor White
Write-Host ""
Write-Host "7. Delete the credentials file securely" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT:" -ForegroundColor Red
Write-Host "   - Old credentials are now useless (history cleaned)" -ForegroundColor White
Write-Host "   - Anyone who cloned the repo needs to re-clone" -ForegroundColor White
Write-Host "   - Keep the new-credentials-*.txt file secure" -ForegroundColor White
Write-Host ""
