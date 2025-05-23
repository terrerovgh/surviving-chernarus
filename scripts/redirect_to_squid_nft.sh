#!/bin/bash

# === Configuration ===
# Network interface for the Wi-Fi Hotspot (LAN)
WLAN_IF="wlan0" # IMPORTANT: User MUST verify and change

# Subnet for the Wi-Fi Hotspot
HOTSPOT_NET="192.168.73.0/24" # IMPORTANT: User MUST verify and change

# IP Address of the Raspberry Pi on the WLAN interface
RPI_WLAN_IP="192.168.73.1" # IMPORTANT: User MUST verify and change

# Port where the Captive Portal Nginx is listening (from docker-compose)
PORTAL_HOST_PORT="8080" # IMPORTANT: User MUST verify and change

# Squid Proxy Ports (ensure these match squid.conf and docker-compose)
SQUID_HTTP_PORT="3128"  # Squid's HTTP listening port
SQUID_HTTPS_PORT="3129" # Squid's HTTPS (ssl-bump) listening port

# === Script Start ===
echo "Starting Squid Proxy Redirect Setup using nftables..."

# Check if nftables is installed
if ! command -v nft &> /dev/null; then
    echo "[ERROR] nftables command could not be found. Please install nftables first."
    echo "You can usually install it with: sudo apt update && sudo apt install nftables -y"
    exit 1
fi

# Ensure base tables and chains are likely present (informational)
echo "[INFO] This script assumes base tables 'inet firewall_table' and 'ip nat_table' exist,"
echo "       and chains 'inet firewall_table input' and 'ip nat_table prerouting' exist."
echo "       These are typically created by 'setup_hotspot_nat_nft.sh' and potentially"
echo "       modified by 'setup_captive_portal_redirect_nft.sh'."

# === 1. PREROUTING Bypass Rules for RPi Local Services ===
# These rules ensure traffic to essential RPi services (DNS, DHCP, local web/portal)
# is NOT redirected to Squid. They are inserted after the captive portal's main redirect rule (pos 0).

# --- Bypass rule for local Web/Portal services (HTTP, HTTPS, Portal Port) ---
BYPASS_WEB_COMMENT="Bypass Squid for RPi Web/Portal (80,443,$PORTAL_HOST_PORT) on $RPI_WLAN_IP"
BYPASS_WEB_CMD="sudo nft insert rule ip nat_table prerouting position 1 iifname \"$WLAN_IF\" ip daddr \"$RPI_WLAN_IP\" tcp dport {80, 443, $PORTAL_HOST_PORT} return comment \"$BYPASS_WEB_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$BYPASS_WEB_COMMENT"; then
    echo "[INFO] Prerouting bypass rule for RPi Web/Portal services already seems to exist. Skipping."
else
    echo "[INFO] Adding PREROUTING bypass rule for RPi Web/Portal services..."
    eval "$BYPASS_WEB_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add PREROUTING bypass for RPi Web/Portal. Exiting."; exit 1; fi
    echo "[SUCCESS] PREROUTING bypass for RPi Web/Portal added."
fi

# --- Bypass rule for local DNS/DHCP services (UDP) ---
BYPASS_DNS_DHCP_COMMENT="Bypass Squid for RPi DNS/DHCP (53,67,68) on $RPI_WLAN_IP"
# Insert after the web bypass rule, so position 2 if web bypass was added, or 1 if not.
# For simplicity, we'll always try to insert at a fixed position relative to the start.
# Assuming captive portal redirect is at 0, web bypass at 1.
BYPASS_DNS_DHCP_CMD="sudo nft insert rule ip nat_table prerouting position 2 iifname \"$WLAN_IF\" ip daddr \"$RPI_WLAN_IP\" udp dport {53, 67, 68} return comment \"$BYPASS_DNS_DHCP_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$BYPASS_DNS_DHCP_COMMENT"; then
    echo "[INFO] Prerouting bypass rule for RPi DNS/DHCP services already seems to exist. Skipping."
else
    echo "[INFO] Adding PREROUTING bypass rule for RPi DNS/DHCP services..."
    eval "$BYPASS_DNS_DHCP_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add PREROUTING bypass for RPi DNS/DHCP. Exiting."; exit 1; fi
    echo "[SUCCESS] PREROUTING bypass for RPi DNS/DHCP added."
fi

# === 2. PREROUTING DNAT Rules for Squid Proxy ===
# These rules redirect HTTP and HTTPS traffic from the hotspot network to Squid.
# They are added after the bypass rules.

# --- DNAT HTTP to Squid ---
SQUID_HTTP_DNAT_COMMENT="DNAT HTTP from $HOTSPOT_NET on $WLAN_IF to Squid 127.0.0.1:$SQUID_HTTP_PORT"
# This rule is added to the end of the chain (append) to ensure it's processed after specific bypasses and portal redirects.
SQUID_HTTP_DNAT_CMD="sudo nft add rule ip nat_table prerouting iifname \"$WLAN_IF\" ip saddr \"$HOTSPOT_NET\" ip daddr != \"$RPI_WLAN_IP\" tcp dport 80 dnat to \"127.0.0.1:$SQUID_HTTP_PORT\" comment \"$SQUID_HTTP_DNAT_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$SQUID_HTTP_DNAT_COMMENT"; then
    echo "[INFO] Prerouting DNAT rule for HTTP to Squid already seems to exist. Skipping."
else
    echo "[INFO] Adding PREROUTING DNAT rule for HTTP to Squid..."
    eval "$SQUID_HTTP_DNAT_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add PREROUTING DNAT for HTTP to Squid. Exiting."; exit 1; fi
    echo "[SUCCESS] PREROUTING DNAT for HTTP to Squid added."
fi

# --- DNAT HTTPS to Squid ---
SQUID_HTTPS_DNAT_COMMENT="DNAT HTTPS from $HOTSPOT_NET on $WLAN_IF to Squid 127.0.0.1:$SQUID_HTTPS_PORT"
SQUID_HTTPS_DNAT_CMD="sudo nft add rule ip nat_table prerouting iifname \"$WLAN_IF\" ip saddr \"$HOTSPOT_NET\" ip daddr != \"$RPI_WLAN_IP\" tcp dport 443 dnat to \"127.0.0.1:$SQUID_HTTPS_PORT\" comment \"$SQUID_HTTPS_DNAT_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$SQUID_HTTPS_DNAT_COMMENT"; then
    echo "[INFO] Prerouting DNAT rule for HTTPS to Squid already seems to exist. Skipping."
else
    echo "[INFO] Adding PREROUTING DNAT rule for HTTPS to Squid..."
    eval "$SQUID_HTTPS_DNAT_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add PREROUTING DNAT for HTTPS to Squid. Exiting."; exit 1; fi
    echo "[SUCCESS] PREROUTING DNAT for HTTPS to Squid added."
fi

# === 3. INPUT Rules for Squid Traffic on Host ===
# These rules allow the RPi itself to accept the traffic redirected to Squid's local ports.

# --- Allow HTTP traffic to local Squid port ---
SQUID_HTTP_INPUT_COMMENT="Allow HTTP from $HOTSPOT_NET on $WLAN_IF to local Squid 127.0.0.1:$SQUID_HTTP_PORT"
SQUID_HTTP_INPUT_CMD="sudo nft add rule inet firewall_table input iifname \"$WLAN_IF\" ip saddr \"$HOTSPOT_NET\" ip daddr \"127.0.0.1\" tcp dport \"$SQUID_HTTP_PORT\" accept comment \"$SQUID_HTTP_INPUT_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$SQUID_HTTP_INPUT_COMMENT"; then
    echo "[INFO] Input rule for local Squid HTTP traffic already seems to exist. Skipping."
else
    echo "[INFO] Adding INPUT rule for local Squid HTTP traffic..."
    eval "$SQUID_HTTP_INPUT_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add INPUT rule for local Squid HTTP. Exiting."; exit 1; fi
    echo "[SUCCESS] INPUT rule for local Squid HTTP added."
fi

# --- Allow HTTPS traffic to local Squid port ---
SQUID_HTTPS_INPUT_COMMENT="Allow HTTPS from $HOTSPOT_NET on $WLAN_IF to local Squid 127.0.0.1:$SQUID_HTTPS_PORT"
SQUID_HTTPS_INPUT_CMD="sudo nft add rule inet firewall_table input iifname \"$WLAN_IF\" ip saddr \"$HOTSPOT_NET\" ip daddr \"127.0.0.1\" tcp dport \"$SQUID_HTTPS_PORT\" accept comment \"$SQUID_HTTPS_INPUT_COMMENT\""

if sudo nft list ruleset | grep -qF -- "$SQUID_HTTPS_INPUT_COMMENT"; then
    echo "[INFO] Input rule for local Squid HTTPS traffic already seems to exist. Skipping."
else
    echo "[INFO] Adding INPUT rule for local Squid HTTPS traffic..."
    eval "$SQUID_HTTPS_INPUT_CMD"
    if [ $? -ne 0 ]; then echo "[ERROR] Failed to add INPUT rule for local Squid HTTPS. Exiting."; exit 1; fi
    echo "[SUCCESS] INPUT rule for local Squid HTTPS added."
fi

echo ""
echo "=== User Guidance ==="
echo "Purpose of this script:"
echo "  - To transparently redirect HTTP (port 80) and HTTPS (port 443) traffic from clients"
echo "    on the '$WLAN_IF' network (subnet $HOTSPOT_NET) to the Squid proxy running locally"
echo "    on ports $SQUID_HTTP_PORT (HTTP) and $SQUID_HTTPS_PORT (HTTPS)."
echo "  - It includes bypass rules to ensure direct access to essential services on the RPi"
echo "    itself (like the captive portal, local web admin, DNS, DHCP) is maintained."
echo ""
echo "Rule Order Considerations:"
echo "  - Captive Portal First: It's assumed that 'setup_captive_portal_redirect_nft.sh' has"
echo "    already run and its primary HTTP redirect rule is at 'position 0' in the"
echo "    'ip nat_table prerouting' chain. This is crucial for unauthenticated users."
echo "  - RPi Service Bypasses: The bypass rules in this script are inserted starting at 'position 1'"
echo "    to ensure they are evaluated AFTER the main captive portal redirect but BEFORE the"
echo "    general Squid DNAT rules. This prevents local RPi services from being proxied."
echo "  - Squid DNAT Rules: These are appended, so they act as general fallbacks for web traffic"
echo "    not caught by the portal redirect or specific RPi service bypasses."
echo "  - INPUT Rules: These allow the traffic, once DNATed to 127.0.0.1, to be accepted by the RPi."
echo ""
echo "Interaction with Captive Portal:"
echo "  - This script should typically be run AFTER users have authenticated through the"
echo "    captive portal. The captive portal system would be responsible for:"
echo "    1. Initially redirecting ALL HTTP traffic to itself (using the rule from"
echo "       'setup_captive_portal_redirect_nft.sh')."
echo "    2. Upon successful authentication, removing or disabling its own broad HTTP redirect rule"
echo "       OR adding more specific rules to allow authenticated users to bypass the portal."
echo "    3. The rules in THIS script then take over to proxy authenticated users' traffic via Squid."
echo "  - If the main captive portal redirect (position 0) remains active and broadly matches all HTTP,"
echo "    the Squid HTTP DNAT rule might not be hit for unauthenticated users. This is generally desired."
echo ""
echo "Persistence:"
echo "  - These rules are temporary. To make them (and all other nftables rules) permanent:"
echo "    1. After running ALL necessary setup scripts (NAT, portal, Squid redirect), save the"
echo "       ENTIRE current ruleset:"
echo "       sudo nft list ruleset > /etc/nftables.conf"
echo "       (This command OVERWRITES /etc/nftables.conf. Review if you have existing rules.)"
echo "    2. Ensure the nftables service is enabled to load rules at boot:"
echo "       sudo systemctl enable nftables.service"
echo "       sudo systemctl start nftables.service (or restart if already running)"
echo ""
echo "To view current rules: sudo nft list ruleset"
echo ""
echo "Squid proxy redirect setup script finished."

exit 0
