#!/usr/bin/env bash
# Clean sensitive data from git history
# This script uses git-filter-repo to remove sensitive files and strings

set -e

echo "=========================================="
echo "Git History Cleanup Script"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will rewrite git history!"
echo "⚠️  All collaborators will need to re-clone the repository."
echo "⚠️  Make sure you have a backup before proceeding."
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Checking if git-filter-repo is installed..."
if ! command -v git-filter-repo &> /dev/null; then
    echo "❌ git-filter-repo not found!"
    echo ""
    echo "Install it with:"
    echo "  pip install git-filter-repo"
    echo "  or"
    echo "  brew install git-filter-repo  (macOS)"
    echo ""
    exit 1
fi
echo "✅ git-filter-repo is installed"

echo ""
echo "Step 2: Creating backup..."
BACKUP_DIR="../openclaw-coolify-backup-$(date +%Y%m%d-%H%M%S)"
cp -r . "$BACKUP_DIR"
echo "✅ Backup created at: $BACKUP_DIR"

echo ""
echo "Step 3: Creating sensitive strings file..."
cat > /tmp/sensitive-strings.txt << 'EOF'
***REMOVED-TOKEN***
***REMOVED-OLD-TOKEN***
***REMOVED-PASSWORD***
***REMOVED-TELEGRAM-ID***
***REMOVED-USERNAME***
***REMOVED-BOT***
***REMOVED-URL***
***REMOVED-DEPLOYMENT-ID***
***REMOVED-VPS***
EOF
echo "✅ Sensitive strings file created"

echo ""
echo "Step 4: Removing sensitive files from history..."
git filter-repo --invert-paths \
    --path scripts/test-authentication.sh \
    --path workspace-files/telegram_history.json \
    --force

echo "✅ Sensitive files removed from history"

echo ""
echo "Step 5: Replacing sensitive strings in history..."
git filter-repo --replace-text /tmp/sensitive-strings.txt --force

echo "✅ Sensitive strings replaced in history"

echo ""
echo "Step 6: Cleaning up..."
rm /tmp/sensitive-strings.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ Cleanup complete"

echo ""
echo "=========================================="
echo "Git History Cleaned Successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the changes: git log --oneline"
echo "2. Force push to GitHub: git push origin main --force"
echo "3. Notify collaborators to re-clone the repository"
echo ""
echo "⚠️  IMPORTANT: After force push, the old history will be gone."
echo "⚠️  Make sure you've rotated the exposed credentials!"
echo ""
