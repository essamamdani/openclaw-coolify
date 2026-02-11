# Rotate exposed credentials
# This script generates new credentials and provides instructions for updating them

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Credential Rotation Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to generate random password
function New-RandomPassword {
    param([int]$Length = 32)
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

# Function to generate hex token
function New-HexToken {
    param([int]$Length = 32)
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
}

Write-Host "Generating new credentials..." -ForegroundColor Green
Write-Host ""

# Generate new HTTP Basic Auth password
$NewPassword = New-RandomPassword -Length 24
Write-Host "1. NEW HTTP BASIC AUTH PASSWORD:" -ForegroundColor Yellow
Write-Host "   $NewPassword" -ForegroundColor White
Write-Host ""

# Generate htpasswd hash (requires Docker)
Write-Host "   Generating htpasswd hash..." -ForegroundColor Cyan
try {
    $HtpasswdHash = docker run --rm httpd:2.4-alpine htpasswd -nbB admin $NewPassword
    Write-Host "   Htpasswd entry:" -ForegroundColor Cyan
    Write-Host "   $HtpasswdHash" -ForegroundColor White
    Write-Host ""
    Write-Host "   ⚠️  IMPORTANT: In docker-compose.yaml, escape $ as $$" -ForegroundColor Yellow
    $EscapedHash = $HtpasswdHash -replace '\$', '$$$$'
    Write-Host "   Escaped for docker-compose.yaml:" -ForegroundColor Cyan
    Write-Host "   $EscapedHash" -ForegroundColor White
} catch {
    Write-Host "   ⚠️  Docker not available. Generate hash manually:" -ForegroundColor Yellow
    Write-Host "   docker run --rm httpd:2.4-alpine htpasswd -nbB admin `"$NewPassword`"" -ForegroundColor White
}

Write-Host ""
Write-Host "2. NEW OPENCLAW GATEWAY TOKEN:" -ForegroundColor Yellow
$NewToken = New-HexToken -Length 32
Write-Host "   $NewToken" -ForegroundColor White
Write-Host ""

# Save to secure file
$CredentialsFile = "new-credentials-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$CredentialsContent = @"
# New Credentials - Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ⚠️  KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT

## HTTP Basic Auth
Username: admin
Password: $NewPassword

## Htpasswd Hash (for docker-compose.yaml)
$HtpasswdHash

## Htpasswd Hash (escaped for docker-compose.yaml)
$EscapedHash

## OpenClaw Gateway Token
$NewToken

## Instructions

### 1. Update docker-compose.yaml
Find the traefik.http.middlewares.openclaw-auth.basicauth.users label and replace with:
  $EscapedHash

### 2. Update OpenClaw Configuration on VPS
SSH into VPS and run:
  ssh ***REMOVED-VPS***
  
  # Get container name
  CONTAINER=$(sudo docker ps --filter name=openclaw-qsw --format '{{.Names}}' | head -1)
  
  # Update token
  sudo docker exec $CONTAINER python3 << 'EOF'
import json
config = json.load(open("/root/.openclaw/openclaw.json"))
config["gateway"]["auth"]["token"] = "$NewToken"
json.dump(config, open("/root/.openclaw/openclaw.json", "w"), indent=2)
print("✅ Token updated successfully!")
EOF
  
  # Restart container
  sudo docker restart $CONTAINER

### 3. Update Your Bookmarks
New dashboard URL:
  ***REMOVED-URL***?token=$NewToken

### 4. Test Access
After updating, test with:
  curl -u admin:$NewPassword ***REMOVED-URL***?token=$NewToken

### 5. Delete This File
After successfully updating all credentials, securely delete this file:
  Remove-Item $CredentialsFile -Force
"@

$CredentialsContent | Out-File -FilePath $CredentialsFile -Encoding UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Credentials Generated Successfully!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ New credentials saved to: $CredentialsFile" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Update docker-compose.yaml with new htpasswd hash" -ForegroundColor White
Write-Host "2. Commit and push changes to trigger Coolify rebuild" -ForegroundColor White
Write-Host "3. SSH into VPS and update OpenClaw token" -ForegroundColor White
Write-Host "4. Test access with new credentials" -ForegroundColor White
Write-Host "5. Delete the credentials file: Remove-Item $CredentialsFile" -ForegroundColor White
Write-Host ""
Write-Host "📄 Full instructions are in: $CredentialsFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT: Add $CredentialsFile to .gitignore!" -ForegroundColor Yellow
Write-Host ""

# Add to .gitignore
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -notmatch "new-credentials-.*\.txt") {
        Add-Content ".gitignore" "`n# Generated credential files`nnew-credentials-*.txt"
        Write-Host "✅ Added new-credentials-*.txt to .gitignore" -ForegroundColor Green
    }
}

Write-Host ""
