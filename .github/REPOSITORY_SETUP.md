# GitHub Repository Configuration
# This file documents the recommended GitHub repository settings for Surviving Chernarus

## Repository Settings

### General Settings
- **Repository name**: `surviving-chernarus`
- **Description**: `🏠 Surviving Chernarus - Hybrid Cloud Infrastructure (Docker + Kubernetes) with automated deployment, monitoring, and security for home lab and small business environments`
- **Visibility**: Public
- **Topics**: `infrastructure`, `kubernetes`, `docker`, `raspberry-pi`, `traefik`, `home-lab`, `automation`, `monitoring`, `devops`, `gitops`

### Features
- [x] Issues
- [x] Discussions
- [x] Wiki
- [x] Projects (optional)
- [x] Security and analysis

### Pull Requests
- [x] Allow merge commits
- [x] Allow squash merging
- [x] Allow rebase merging
- [x] Automatically delete head branches

### Branch Protection Rules

#### Main Branch (`main`)
- [x] Require pull request reviews before merging
- [x] Require review from CODEOWNERS
- [x] Dismiss stale PR approvals when new commits are pushed
- [x] Require status checks to pass before merging
  - Required status checks:
    - `Lint and Validate`
    - `Security Scan`
    - `Test Docker Build`
    - `Test Kubernetes Deployment`
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Include administrators in restrictions

#### Develop Branch (`develop`)
- [x] Require pull request reviews before merging
- [x] Require status checks to pass before merging
  - Required status checks:
    - `Lint and Validate`
    - `Security Scan`

### Environments

#### Production Environment
- **Environment name**: `production`
- **Protection rules**:
  - Required reviewers: terrerovgh
  - Wait timer: 5 minutes
  - Deployment branches: `main` only
- **Environment secrets**:
  - `SSH_PRIVATE_KEY`: SSH private key for deployment
  - `RPI_HOST`: Raspberry Pi hostname/IP
  - `RPI_USER`: SSH user for Raspberry Pi
  - `LENLAB_HOST`: Lenlab server hostname/IP
  - `LENLAB_USER`: SSH user for Lenlab server
  - `KUBECONFIG`: Base64-encoded kubeconfig for cluster access

#### Staging Environment
- **Environment name**: `staging`
- **Protection rules**:
  - Deployment branches: `develop` and `main`
- **Environment secrets**: (same as production but for staging infrastructure)

### Repository Secrets
- `GITHUB_TOKEN`: Automatically provided
- `CODECOV_TOKEN`: (optional) For code coverage reporting

### Security Settings
- [x] Dependency graph
- [x] Dependabot alerts
- [x] Dependabot security updates
- [x] Code scanning alerts
- [x] Secret scanning alerts
- [x] Private vulnerability reporting

### Collaborators and Teams
- **Owner**: terrerovgh (Admin)
- **Contributors**: (Add as needed)

### GitHub Pages (Optional)
- **Source**: Deploy from branch `gh-pages` or GitHub Actions
- **Custom domain**: (optional) docs.yourdomain.com

### Social Preview
- Upload a custom social preview image showcasing the infrastructure diagram

## Initial Setup Commands

After creating the repository on GitHub, run these commands locally:

```bash
# Add remote and push to GitHub
git remote add origin https://github.com/terrerovgh/surviving-chernarus.git
git branch -M main
git push -u origin main

# Create and push develop branch
git checkout -b develop
git push -u origin develop
git checkout main
```

## Webhook Configuration (Optional)

For advanced integrations:
- **Discord/Slack notifications**: Configure webhooks for deployment notifications
- **Monitoring integration**: Webhook for external monitoring systems
- **CI/CD triggers**: Integration with external deployment systems

## GitHub CLI Configuration

```bash
# Install GitHub CLI and authenticate
gh auth login

# Set repository topics
gh repo edit terrerovgh/surviving-chernarus --add-topic infrastructure,kubernetes,docker,raspberry-pi,traefik,home-lab,automation,monitoring,devops,gitops

# Enable features
gh repo edit terrerovgh/surviving-chernarus --enable-issues --enable-discussions --enable-wiki

# Create environments
gh api repos/terrerovgh/surviving-chernarus/environments -f name=production
gh api repos/terrerovgh/surviving-chernarus/environments -f name=staging
```

## Post-Setup Checklist

- [ ] Repository created with correct name and description
- [ ] Topics added for discoverability
- [ ] Branch protection rules configured
- [ ] Environments created (production, staging)
- [ ] Required secrets added to environments
- [ ] Security features enabled
- [ ] Issue templates working
- [ ] GitHub Actions workflows passing
- [ ] Repository visibility set to Public
- [ ] Social preview image uploaded (optional)
- [ ] Wiki initialized with key documentation (optional)
- [ ] Discussions enabled for community support
