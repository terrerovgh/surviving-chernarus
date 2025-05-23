#!/bin/bash

# === Configuration ===
# Network interface for the Wi-Fi Hotspot (LAN)
# IMPORTANT: User MUST verify and change this to their actual WLAN interface
WLAN_IF="wlan0"

# IP Address of the Raspberry Pi on the WLAN interface
# This is where the captive portal Nginx service is listening.
# IMPORTANT: User MUST verify and change this to the RPi's actual IP on WLAN_IF
RPI_WLAN_IP="192.168.73.1" # Example: Match this with your Pi-hole/DHCP setup for WLAN

# Port where the Captive Portal Nginx is listening (Host Port from docker-compose)
PORTAL_HOST_PORT="8080"

# === Script Start ===
echo "Starting Captive Portal Redirect Setup using nftables..."

# Check if nftables is installed
if ! command -v nft &> /dev/null; then
    echo "[ERROR] nftables command could not be found. Please install nftables first."
    echo "You can usually install it with: sudo apt update && sudo apt install nftables -y"
    exit 1
fi

# Ensure base tables and chains are likely present (informational)
echo "[INFO] This script assumes base tables 'inet firewall_table' and 'ip nat_table' exist,"
echo "       and chains 'inet firewall_table input' and 'ip nat_table prerouting' exist."
echo "       These are typically created by a base firewall script like 'setup_hotspot_nat_nft.sh'."

# === 1. Add INPUT rule for Captive Portal Service ===
# This rule allows clients on the WLAN to connect to the portal service on the RPi.
INPUT_RULE_COMMENT="Allow TCP to Captive Portal on $RPI_WLAN_IP:$PORTAL_HOST_PORT from $WLAN_IF"
INPUT_RULE_CMD="sudo nft add rule inet firewall_table input iifname \"$WLAN_IF\" ip daddr \"$RPI_WLAN_IP\" tcp dport \"$PORTAL_HOST_PORT\" accept comment \"$INPUT_RULE_COMMENT\""

# Check if the INPUT rule or a similar one already exists to avoid duplicates
if sudo nft list ruleset | grep -qF -- "$INPUT_RULE_COMMENT"; then
    echo "[INFO] Input rule for captive portal service already seems to exist. Skipping addition."
else
    echo "[INFO] Adding INPUT rule for captive portal service..."
    eval "$INPUT_RULE_CMD"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to add INPUT rule for captive portal. Exiting."
        exit 1
    fi
    echo "[SUCCESS] INPUT rule added."
fi

# === 2. Add PREROUTING rule for HTTP Redirection ===
# This rule redirects HTTP (port 80) traffic from any client on WLAN_IF
# to the captive portal running on the RPi.
# We only redirect traffic not already destined for the RPi itself to avoid loops.
PREROUTING_RULE_COMMENT="DNAT HTTP from $WLAN_IF to Captive Portal $RPI_WLAN_IP:$PORTAL_HOST_PORT"
# Using 'insert' to ensure high precedence for redirection.
# It redirects traffic that is NOT already going to RPI_WLAN_IP to avoid loops if portal is on same IP.
PREROUTING_RULE_CMD="sudo nft insert rule ip nat_table prerouting position 0 iifname \"$WLAN_IF\" ip daddr != \"$RPI_WLAN_IP\" tcp dport 80 dnat to \"$RPI_WLAN_IP:$PORTAL_HOST_PORT\" comment \"$PREROUTING_RULE_COMMENT\""

# Check if the PREROUTING rule or a similar one already exists
if sudo nft list ruleset | grep -qF -- "$PREROUTING_RULE_COMMENT"; then
    echo "[INFO] Prerouting rule for HTTP redirection already seems to exist. Skipping addition."
else
    echo "[INFO] Adding PREROUTING rule for HTTP redirection..."
    eval "$PREROUTING_RULE_CMD"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to add PREROUTING rule for HTTP redirection. Exiting."
        exit 1
    fi
    echo "[SUCCESS] PREROUTING rule added."
fi

echo ""
echo "=== User Guidance ==="
echo "Purpose of this script:"
echo "  - To redirect unauthenticated users on the '$WLAN_IF' network to the"
echo "    captive portal running at $RPI_WLAN_IP:$PORTAL_HOST_PORT."
echo "  - It allows access to the portal itself and then redirects HTTP traffic to it."
echo ""
echo "Limitations:"
echo "  - HTTPS Redirection: This script ONLY redirects HTTP (port 80) traffic."
echo "    Users trying to access HTTPS sites directly might see timeout errors or"
echo "    certificate warnings if they haven't authenticated via an HTTP site first."
echo "    Full HTTPS interception (like Squid with SSL Bump) is required for seamless"
echo "    HTTPS redirection, which is complex and has security implications."
echo "  - Persistent Redirection: Once these rules are active, HTTP traffic will"
echo "    continue to be redirected until the rules are removed or modified."
echo "    Your captive portal application should handle 'un-redirecting' clients"
echo "    after they authenticate (e.g., by using firewall rules based on MAC/IP)."
echo ""
echo "Rule Order & Persistence:"
echo "  - Rule Order: The PREROUTING rule for DNAT is inserted at 'position 0' to ensure"
echo "    it's processed before other general NAT rules (like masquerading)."
echo "    The INPUT rule for portal access is less sensitive to order but must exist."
echo "  - Persistence: These rules are temporary. To make them (and all other nftables rules)"
echo "    permanent and survive reboots:"
echo "    1. After running ALL necessary setup scripts (NAT, portal, etc.), save the"
echo "       ENTIRE current ruleset:"
echo "       sudo nft list ruleset > /etc/nftables.conf"
echo "       (This command OVERWRITES /etc/nftables.conf. Review if you have existing rules.)"
echo "    2. Ensure the nftables service is enabled to load rules at boot:"
echo "       sudo systemctl enable nftables.service"
echo "       sudo systemctl start nftables.service (or restart if already running)"
echo ""
echo "To view current rules: sudo nft list ruleset"
echo ""
echo "Captive portal redirect setup script finished."

exit 0
