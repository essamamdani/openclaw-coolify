# Clean sensitive data from git history
# This script uses git-filter-repo to remove sensitive files and strings

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Git History Cleanup Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This will rewrite git history!" -ForegroundColor Yellow
Write-Host "⚠️  All collaborators will need to re-clone the repository." -ForegroundColor Yellow
Write-Host "⚠️  Make sure you have a backup before proceeding." -ForegroundColor Yellow
Write-Host ""

$Confirm = Read-Host "Do you want to continue? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 1: Checking if git-filter-repo is installed..." -ForegroundColor Green

try {
    $filterRepoVersion = python -m git_filter_repo --version 2>&1
    Write-Host "✅ git-filter-repo is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ git-filter-repo not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install it with:" -ForegroundColor Yellow
    Write-Host "  pip install git-filter-repo" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Step 2: Creating backup..." -ForegroundColor Green
$BackupDir = "..\openclaw-coolify-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path . -Destination $BackupDir -Recurse -Force
Write-Host "✅ Backup created at: $BackupDir" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Creating sensitive strings file..." -ForegroundColor Green
$SensitiveStrings = @"
***REMOVED-TOKEN***==>***REMOVED-TOKEN***
***REMOVED-OLD-TOKEN***==>***REMOVED-OLD-TOKEN***
***REMOVED-PASSWORD***==>***REMOVED-PASSWORD***
***REMOVED-TELEGRAM-ID***==>***REMOVED-TELEGRAM-ID***
***REMOVED-USERNAME***==>***REMOVED-USERNAME***
***REMOVED-BOT***==>***REMOVED-BOT***
***REMOVED-URL***==>***REMOVED-URL***
***REMOVED-DEPLOYMENT-ID***==>***REMOVED-DEPLOYMENT-ID***
***REMOVED-VPS***==>***REMOVED-VPS***
"@
$SensitiveStrings | Out-File -FilePath "$env:TEMP\sensitive-strings.txt" -Encoding UTF8
Write-Host "✅ Sensitive strings file created" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Removing sensitive files from history..." -ForegroundColor Green
python -m git_filter_repo --invert-paths `
    --path scripts/test-authentication.sh `
    --path workspace-files/telegram_history.json `
    --force

Write-Host "✅ Sensitive files removed from history" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Replacing sensitive strings in history..." -ForegroundColor Green
python -m git_filter_repo --replace-text "$env:TEMP\sensitive-strings.txt" --force

Write-Host "✅ Sensitive strings replaced in history" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Cleaning up..." -ForegroundColor Green
Remove-Item "$env:TEMP\sensitive-strings.txt" -Force
git reflog expire --expire=now --all
git gc --prune=now --aggressive

Write-Host "✅ Cleanup complete" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Git History Cleaned Successfully!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the changes: git log --oneline" -ForegroundColor White
Write-Host "2. Force push to GitHub: git push origin main --force" -ForegroundColor White
Write-Host "3. Notify collaborators to re-clone the repository" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: After force push, the old history will be gone." -ForegroundColor Yellow
Write-Host "⚠️  Make sure you've rotated the exposed credentials!" -ForegroundColor Yellow
Write-Host ""
