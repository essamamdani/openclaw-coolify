# Security Policy

## Secret Scanning

This repository has multiple layers of protection against committing secrets:

### 1. Pre-commit Hook
A Git pre-commit hook automatically scans all staged files for:
- API keys (Anthropic, OpenAI, Gemini, GitHub, etc.)
- Tokens (Telegram, authentication tokens)
- Private keys (SSH, SSL/TLS)
- Database connection strings with passwords
- AWS credentials
- Generic secret patterns

**Location:** `.git/hooks/pre-commit`

### 2. .gitignore Protection
Comprehensive `.gitignore` rules prevent sensitive files from being staged:
- `.env` and `.env.*` files (except `.env.example`)
- Private keys (`.pem`, `.key`, `.p12`, etc.)
- Credential files
- Backup files containing secrets

### 3. .gitattributes Filters
Additional protection for sensitive file types using Git filters.

### 4. Secrets Baseline
Configuration file (`.secrets-baseline.json`) defines patterns and allowed exceptions.

## What to Do If You Find a Secret

If you discover a secret has been committed:

1. **Immediately rotate the secret** - Generate a new key/token
2. **Remove from repository** - Edit the file and replace with placeholder
3. **Commit the fix** - Push the corrected version
4. **Document the incident** - Update SECURITY_NOTICE.md if needed

## Bypassing the Pre-commit Hook

**⚠️ NOT RECOMMENDED** - Only use in exceptional cases:

```bash
git commit --no-verify
```

This should only be used when:
- You're committing example/placeholder values
- The pre-commit hook has a false positive
- You've verified the content is safe

## Testing the Protection

To test if the pre-commit hook is working:

```bash
# Try to commit a file with a fake API key
echo "ANTHROPIC_API_KEY=sk-ant-test123456789" > test-secret.txt
git add test-secret.txt
git commit -m "test"
# Should be blocked!
```

## Reporting Security Issues

If you discover a security vulnerability, please email the repository owner directly rather than creating a public issue.

## Best Practices

1. **Never commit secrets** - Use environment variables
2. **Use .env files** - They're gitignored by default
3. **Use placeholders** - In example files, use `YOUR_API_KEY_HERE`
4. **Rotate regularly** - Change tokens every 90 days
5. **Review before pushing** - Always check `git diff` before committing
6. **Enable 2FA** - On GitHub and all services with API keys

## Secret Storage

**Recommended approaches:**
- Environment variables in Coolify dashboard
- Secure vaults (HashiCorp Vault, AWS Secrets Manager)
- Encrypted configuration files (git-crypt, SOPS)
- Password managers for personal tokens

**Never:**
- Commit secrets to Git
- Share secrets in chat/email
- Store secrets in plain text files
- Use the same secret across multiple services
