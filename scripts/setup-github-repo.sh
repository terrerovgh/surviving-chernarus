#!/bin/bash
# setup-github-repo.sh - Script para configurar el repositorio de GitHub
# Surviving Chernarus Project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Configuration
REPO_OWNER="terrerovgh"
REPO_NAME="surviving-chernarus"
REPO_FULL_NAME="$REPO_OWNER/$REPO_NAME"

main() {
    log_info "🚀 Setting up GitHub repository: $REPO_FULL_NAME"

    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it first:"
        echo "  https://cli.github.com/"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_warning "Not authenticated with GitHub CLI"
        log_info "Please run: gh auth login"
        exit 1
    fi

    # Check if repository exists
    if gh repo view "$REPO_FULL_NAME" &> /dev/null; then
        log_info "Repository $REPO_FULL_NAME already exists"
    else
        log_info "Creating repository $REPO_FULL_NAME..."
        gh repo create "$REPO_FULL_NAME" --public --description "🏠 Surviving Chernarus - Hybrid Cloud Infrastructure (Docker + Kubernetes) with automated deployment, monitoring, and security for home lab and small business environments"
    fi

    # Set repository topics
    log_info "Setting repository topics..."
    gh repo edit "$REPO_FULL_NAME" \
        --add-topic infrastructure \
        --add-topic kubernetes \
        --add-topic docker \
        --add-topic raspberry-pi \
        --add-topic traefik \
        --add-topic home-lab \
        --add-topic automation \
        --add-topic monitoring \
        --add-topic devops \
        --add-topic gitops

    # Enable repository features
    log_info "Enabling repository features..."
    gh repo edit "$REPO_FULL_NAME" \
        --enable-issues \
        --enable-discussions \
        --enable-wiki

    # Create environments
    log_info "Creating environments..."
    create_environment "production"
    create_environment "staging"

    # Push code to repository
    log_info "Setting up remote and pushing code..."
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "https://github.com/$REPO_FULL_NAME.git"
    fi

    git branch -M main
    git push -u origin main

    # Create develop branch
    if ! git show-ref --verify --quiet refs/heads/develop; then
        log_info "Creating develop branch..."
        git checkout -b develop
        git push -u origin develop
        git checkout main
    fi

    log_success "✅ Repository setup completed!"
    echo
    log_info "📋 Next steps:"
    echo "1. Visit https://github.com/$REPO_FULL_NAME/settings"
    echo "2. Configure branch protection rules for main and develop branches"
    echo "3. Add required secrets to environments (SSH_PRIVATE_KEY, RPI_HOST, etc.)"
    echo "4. Enable security features (Dependabot, code scanning)"
    echo "5. Upload a social preview image"
    echo
    log_info "📖 See .github/REPOSITORY_SETUP.md for detailed configuration guide"
}

create_environment() {
    local env_name="$1"
    log_info "Creating environment: $env_name"

    if gh api "repos/$REPO_FULL_NAME/environments/$env_name" &> /dev/null; then
        log_info "Environment $env_name already exists"
    else
        gh api "repos/$REPO_FULL_NAME/environments" -f name="$env_name" > /dev/null
        log_success "Created environment: $env_name"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
}

# Trap cleanup on script exit
trap cleanup EXIT

# Run main function
main "$@"
