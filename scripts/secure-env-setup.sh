#!/bin/bash
# secure-env-setup.sh - Configuración segura de variables de entorno
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$PROJECT_DIR")"
SECURE_ENV_FILE="$PARENT_DIR/surviving-chernarus.env"
PROJECT_ENV_FILE="$PROJECT_DIR/.env"

main() {
    log_info "🔐 Setting up secure environment configuration..."

    # Check if .env already exists
    if [[ -f "$PROJECT_ENV_FILE" ]]; then
        log_warning "Found existing .env file in project directory"

        # Check if it contains sensitive data
        if grep -qE "(real_password|actual_token|github_pat_|@.*\.com)" "$PROJECT_ENV_FILE" 2>/dev/null; then
            log_error "⚠️  SECURITY ALERT: .env file contains sensitive information!"
            echo
            echo "This file contains:"
            echo "- Personal email addresses"
            echo "- Real passwords"
            echo "- API tokens"
            echo "- GitHub tokens"
            echo
            read -p "Do you want to move it to a secure location? (y/N): " confirm

            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Backup the current .env
                log_info "Creating backup and moving .env file..."
                cp "$PROJECT_ENV_FILE" "$SECURE_ENV_FILE"
                rm "$PROJECT_ENV_FILE"

                # Create symlink
                ln -s "$SECURE_ENV_FILE" "$PROJECT_ENV_FILE"

                # Set secure permissions
                chmod 600 "$SECURE_ENV_FILE"

                log_success "✅ .env file moved to secure location: $SECURE_ENV_FILE"
                log_info "📁 Created symlink: .env -> $SECURE_ENV_FILE"
            else
                log_warning "⚠️  Please manually secure your .env file before committing!"
                return 1
            fi
        else
            log_info "Current .env file appears to be safe (no sensitive data detected)"
        fi
    else
        log_info "No existing .env file found"

        # Create new .env from example
        if [[ -f "$PROJECT_DIR/.env.example" ]]; then
            log_info "Creating new .env file from .env.example..."
            cp "$PROJECT_DIR/.env.example" "$SECURE_ENV_FILE"
            ln -s "$SECURE_ENV_FILE" "$PROJECT_ENV_FILE"
            chmod 600 "$SECURE_ENV_FILE"

            log_success "✅ Created new .env file: $SECURE_ENV_FILE"
            log_info "📝 Please edit this file with your actual configuration"
        else
            log_error ".env.example not found!"
            return 1
        fi
    fi

    # Verify gitignore
    if grep -q "^\.env$" "$PROJECT_DIR/.gitignore"; then
        log_success "✅ .gitignore correctly excludes .env files"
    else
        log_warning "Adding .env to .gitignore..."
        echo ".env" >> "$PROJECT_DIR/.gitignore"
    fi

    # Security recommendations
    echo
    log_info "🛡️  Security Recommendations:"
    echo "1. Edit $SECURE_ENV_FILE with your actual configuration"
    echo "2. Generate strong passwords using: openssl rand -base64 32"
    echo "3. Generate secrets using: openssl rand -hex 32"
    echo "4. Never share the .env file via email or chat"
    echo "5. Use different .env files for different environments"
    echo
    log_info "📖 For detailed security guidelines, see docs/ENVIRONMENT_SECURITY.md"

    # Verify setup
    echo
    log_info "🔍 Verifying setup..."

    if [[ -L "$PROJECT_ENV_FILE" ]]; then
        log_success "✅ .env is a symlink (secure)"
    else
        log_warning "⚠️  .env is not a symlink"
    fi

    if [[ -f "$SECURE_ENV_FILE" ]]; then
        perms=$(stat -c "%a" "$SECURE_ENV_FILE" 2>/dev/null || stat -f "%A" "$SECURE_ENV_FILE" 2>/dev/null || echo "unknown")
        if [[ "$perms" == "600" ]]; then
            log_success "✅ .env file has secure permissions (600)"
        else
            log_warning "⚠️  .env file permissions: $perms (should be 600)"
            chmod 600 "$SECURE_ENV_FILE"
            log_success "✅ Fixed permissions to 600"
        fi
    fi

    log_success "🎉 Secure environment setup completed!"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
}

# Trap cleanup on script exit
trap cleanup EXIT

# Run main function
main "$@"
