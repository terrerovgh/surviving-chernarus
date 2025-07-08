# 🔐 Environment Variables Security Guide

## 📋 Overview

This guide provides security best practices for managing environment variables
in Surviving Chernarus.

## 🚨 Critical Security Rules

### ❌ NEVER DO

- **Never commit `.env` files to version control**
- Never include real passwords or tokens in `.env.example`
- Never share your `.env` file via email, chat, or public channels
- Never use default or weak passwords in production

### ✅ ALWAYS DO

- Use strong, unique passwords for every service
- Generate random secrets using `openssl rand -hex 32`
- Store `.env` file outside the project directory if possible
- Use different `.env` files for different environments

## 🛡️ Secure Setup Process

### 1. Initial Setup

```bash
# Copy the example file
cp .env.example .env

# Move .env outside project directory (recommended)
mv .env ../surviving-chernarus.env
ln -s ../surviving-chernarus.env .env

# Set secure permissions
chmod 600 .env
```

### 2. Generate Secure Secrets

```bash
# PostgreSQL password
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)" >> .env

# N8N encryption key
echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env

# Application secrets
echo "APP_SECRET_KEY=$(openssl rand -hex 32)" >> .env
echo "JWT_SECRET_KEY=$(openssl rand -hex 32)" >> .env
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env
```

### 3. Service-Specific Configuration

#### Cloudflare API Keys

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create a Zone:Read token for your domain
3. Add to `.env`:

```bash
CLOUDFLARE_EMAIL=your-email@domain.com
CLOUDFLARE_ZONE_API_TOKEN=your_secure_token_here
```

#### Telegram Bot (Optional)

1. Create bot with @BotFather on Telegram
2. Get your chat ID from @userinfobot
3. Add to `.env`:

```bash
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
```

#### GitHub Token (Optional)

1. Go to https://github.com/settings/tokens
2. Create token with repo permissions
3. Add to `.env`:

```bash
GITHUB_TOKEN=your_github_token_here
```

## 🔧 Environment-Specific Configuration

### Development Environment

```bash
# Create development-specific file
cp .env.example .env.development

# Use local services
POSTGRES_HOST=localhost
TRAEFIK_API_INSECURE=true
DEBUG=true
```

### Production Environment

```bash
# Create production-specific file
cp .env.example .env.production

# Use secure configuration
TRAEFIK_API_INSECURE=false
DEBUG=false
ENVIRONMENT=production
```

### Staging Environment

```bash
# Create staging-specific file
cp .env.example .env.staging

# Use staging-specific configuration
ENVIRONMENT=staging
```

## 🏗️ Advanced Security Setup

### 1. External Secret Management

For production deployments, consider using external secret management:

#### HashiCorp Vault

```bash
# Example: Store secrets in Vault
vault kv put secret/chernarus \
  postgres_password="$(openssl rand -base64 32)" \
  n8n_encryption_key="$(openssl rand -hex 32)"
```

#### Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: chernarus-secrets
type: Opaque
data:
  postgres-password: <base64-encoded-password>
  n8n-encryption-key: <base64-encoded-key>
```

### 2. Environment Variable Validation

Create a validation script:

```bash
#!/bin/bash
# validate-env.sh
required_vars=(
  "YOUR_DOMAIN_NAME"
  "POSTGRES_PASSWORD"
  "N8N_ENCRYPTION_KEY"
  "ADMIN_EMAIL"
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "ERROR: $var is not set"
    exit 1
  fi
done

echo "✅ All required environment variables are set"
```

### 3. Secret Rotation

Implement regular secret rotation:

```bash
#!/bin/bash
# rotate-secrets.sh
echo "Rotating secrets..."

# Generate new secrets
NEW_POSTGRES_PASSWORD=$(openssl rand -base64 32)
NEW_N8N_KEY=$(openssl rand -hex 32)

# Update .env file
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_POSTGRES_PASSWORD/" .env
sed -i "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$NEW_N8N_KEY/" .env

echo "✅ Secrets rotated successfully"
```

## 📊 Security Monitoring

### 1. Environment Variable Leaks

Monitor for accidental exposure:

```bash
# Check for .env files in git
git log --all --grep="\.env" --oneline

# Check for secrets in commits
git log --all -p | grep -i "password\|secret\|key\|token"
```

### 2. File Permissions

Regularly check file permissions:

```bash
# Check .env file permissions
ls -la .env
# Should be: -rw------- (600)

# Fix if necessary
chmod 600 .env
```

## 🚨 Incident Response

### If Secrets Are Compromised

1. **Immediately rotate all affected secrets**
2. **Check git history for leaks**
3. **Revoke API tokens/keys**
4. **Generate new certificates if needed**
5. **Review access logs**
6. **Update security documentation**

### Emergency Commands

```bash
# Quick secret rotation
./scripts/rotate-secrets.sh

# Remove secrets from git history (if accidentally committed)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (DANGEROUS - coordinate with team)
git push origin --force --all
```

## 📝 Security Checklist

### Initial Setup

- [ ] `.env` file is not in version control
- [ ] All default passwords changed
- [ ] Strong, unique passwords generated
- [ ] File permissions set to 600
- [ ] Environment variables validated

### Production Deployment

- [ ] Production-specific `.env` created
- [ ] Debug mode disabled
- [ ] SSL/TLS enabled for all services
- [ ] Firewall rules configured
- [ ] Monitoring and alerting set up
- [ ] Backup and recovery tested

### Ongoing Maintenance

- [ ] Regular secret rotation
- [ ] Security updates applied
- [ ] Access logs monitored
- [ ] Incident response plan updated
- [ ] Security documentation current

## 📞 Support

For security-related questions:

- Review the main [SECURITY.md](SECURITY.md) file
- Check the project documentation
- Create a private security issue on GitHub

Remember: Security is everyone's responsibility! 🛡️
