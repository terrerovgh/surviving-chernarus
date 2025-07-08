#!/bin/bash

# 🌐 Fix Network Configuration Script
# Fixes the subnet mask from /25 to /24 for proper connectivity with rpi

set -euo pipefail

echo "🌐 Fixing Network Configuration for Chernarus Infrastructure"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Backup current netplan configuration
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
BACKUP_FILE="/etc/netplan/01-netcfg.yaml.backup.$(date +%Y%m%d_%H%M%S)"

print_status "Creating backup of current netplan configuration..."
cp "$NETPLAN_FILE" "$BACKUP_FILE"
print_status "Backup created: $BACKUP_FILE"

# Create the corrected netplan configuration
print_status "Creating corrected netplan configuration..."
cat > "$NETPLAN_FILE" << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0:
      dhcp4: no
      addresses: [192.168.0.3/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [192.168.0.2,1.1.1.1,192.168.0.3]
EOF

print_status "Updated netplan configuration:"
cat "$NETPLAN_FILE"

# Apply the new configuration
print_status "Applying new network configuration..."
netplan apply

# Wait a moment for the configuration to apply
sleep 2

# Show current network status
print_status "Current network configuration:"
ip addr show enp2s0

print_status "Current routing table:"
ip route

# Test connectivity to rpi
print_status "Testing connectivity to Raspberry Pi (192.168.0.2)..."
if ping -c 3 192.168.0.2; then
    print_status "✅ Successfully connected to Raspberry Pi!"
else
    print_warning "⚠️  Still cannot reach Raspberry Pi. Manual configuration may be needed."
fi

print_status "Network configuration fix completed!"
print_status "You should now be able to SSH to the Raspberry Pi: ssh pi@192.168.0.2"
