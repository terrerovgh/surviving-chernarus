#!/bin/bash
# Script for redirecting new hotspot users to the Chernarus_Entrypoint captive portal.
# This script should ideally be run AFTER basic NAT/forwarding for the hotspot is set up
# (e.g., by setup_hotspot_nat.sh) but BEFORE traffic is redirected to Squid
# (e.g., by redirect_to_squid.sh).
# The goal is to intercept HTTP traffic from new users and show them the portal page.

# === Variables ===
WLAN_IF="wlan0"                     # Interface for the hotspot
RPI_WLAN_IP="192.168.73.1"          # IP address of the Raspberry Pi on the wlan0 network
PORTAL_HOST_PORT="8080"             # Host port where Chernarus_Entrypoint (Nginx) is exposed
SQUID_HTTP_PORT="3128"              # Squid's HTTP listening port

# === Important: Rule Order and Strategy ===
# This script uses a simple approach: redirect ALL HTTP (port 80) traffic from the hotspot
# network to the captive portal.
#
# 1. New user connects, makes an HTTP request (e.g., to http://example.com).
# 2. This PREROUTING rule catches it and redirects to the portal (192.168.73.1:8080).
# 3. User sees instructions, downloads & installs CA.
# 4. HTTPS sites then work via Squid (Berezino_Checkpoint).
#
# Limitation: HTTP sites will *continue* to redirect to the portal with this simple rule.
# This might be acceptable if most critical browsing is HTTPS.
#
# For this to work correctly with the Squid proxy, this DNAT rule for the portal
# MUST take precedence over the DNAT rule that sends port 80 traffic to Squid.
# `iptables` rules are processed in order. One way to ensure precedence is to:
#    a) Insert this rule at the top of the PREROUTING chain.
#    b) Flush PREROUTING rules and apply them in the desired order:
#       1. Portal Redirection (this script)
#       2. Squid Redirection (from redirect_to_squid.sh)
#
# This script will insert the rule at the top of PREROUTING for -t nat.

echo "Ensuring kernel parameters are set for forwarding..."
# Should already be set by setup_hotspot_nat.sh, but good to ensure
sudo sysctl -w net.ipv4.ip_forward=1
# For transparent proxying and NAT, bridge netfilter might be needed if complex Docker networks involved
# sudo sysctl -w net.bridge.bridge-nf-call-iptables=1 # Usually not needed for this direct DNAT approach

echo "Flushing PREROUTING rules in 'nat' table for $WLAN_IF to ensure correct order (USE WITH CAUTION if other rules exist)..."
# WARNING: This is a broad flush for the interface. If you have other critical PREROUTING rules
# for wlan0 not managed by these scripts, this approach needs refinement.
# A more targeted way would be to check if the rule exists and delete it before adding,
# or use a dedicated chain. For simplicity in this project, we'll flush and re-add.
# Consider a dedicated chain for project-specific rules if this becomes complex.
# sudo iptables -t nat -F PREROUTING # Too broad. Let's be more specific or rely on order of execution.
# For now, we will rely on the user running scripts in the correct order:
# 1. setup_hotspot_nat.sh (general NAT/Forward)
# 2. setup_captive_portal_redirect.sh (portal HTTP redirect - INSERTED FIRST)
# 3. redirect_to_squid.sh (Squid HTTP/HTTPS redirect - added after portal rule)

# === Allow Traffic TO the Portal Service on the RPi ===
echo "Allowing INPUT traffic to the portal service on $RPI_WLAN_IP:$PORTAL_HOST_PORT..."
# This ensures that traffic redirected to the RPi itself can reach the Nginx container.
# Check if rule exists before adding
sudo iptables -C INPUT -i $WLAN_IF -p tcp -d $RPI_WLAN_IP --dport $PORTAL_HOST_PORT -j ACCEPT 2>/dev/null || \
    sudo iptables -A INPUT -i $WLAN_IF -p tcp -d $RPI_WLAN_IP --dport $PORTAL_HOST_PORT -j ACCEPT

# === Captive Portal Redirection Rule ===
# Redirect HTTP (port 80) traffic originating from the hotspot network,
# and NOT destined for the RPi itself (to avoid loops if portal was on port 80),
# to the Nginx portal on $RPI_WLAN_IP:$PORTAL_HOST_PORT.
# The `-I PREROUTING 1` inserts the rule at the top (index 1).
echo "Inserting captive portal HTTP redirection rule at the top of PREROUTING (nat table)..."
sudo iptables -t nat -C PREROUTING -i $WLAN_IF -p tcp --dport 80 -j DNAT --to-destination $RPI_WLAN_IP:$PORTAL_HOST_PORT 2>/dev/null || \
    sudo iptables -t nat -I PREROUTING 1 -i $WLAN_IF -p tcp --dport 80 -j DNAT --to-destination $RPI_WLAN_IP:$PORTAL_HOST_PORT

# === Explanations and Warnings ===
echo ""
echo "--- Captive Portal Redirection Strategy ---"
echo "The 'iptables' rule added by this script redirects all HTTP (port 80) requests from hotspot clients"
echo "on interface '$WLAN_IF' to the Chernarus_Entrypoint portal page at $RPI_WLAN_IP:$PORTAL_HOST_PORT."
echo ""
echo "How it works (Simplified Approach):"
echo "1. A new user connects. Any HTTP request they make (e.g., to http://example.com) gets redirected."
echo "2. They see the index.html page with instructions to download and install the CA certificate."
echo "3. Once they install the CA certificate, HTTPS sites should start working correctly via the Squid proxy (Berezino_Checkpoint)."
echo ""
echo "Limitation:"
echo "With this simple rule, HTTP sites will *continue* to redirect to the portal even after CA installation."
echo "Given most important web traffic is HTTPS, this might be an acceptable trade-off for simplicity."
echo "Users wanting to access an HTTP site directly would be unable to without modifying these rules."
echo ""
echo "Alternative (Manual Access):"
echo "Do not implement this automatic redirection. Instead, instruct users to manually visit http://$RPI_WLAN_IP:$PORTAL_HOST_PORT"
echo "(or a custom domain like 'http://welcome.chernarus.local' if you set up a DNS entry in Pi-hole pointing"
echo "to $RPI_WLAN_IP and change Nginx in docker-compose.yml for Chernarus_Entrypoint to listen on port 80, e.g., '80:80')."
echo ""
echo "Order of Rules is CRITICAL:"
echo "This script attempts to insert the portal redirection rule at the beginning of the PREROUTING chain in the 'nat' table."
echo "This is to ensure it's processed BEFORE any rule that might redirect HTTP traffic to Squid."
echo "The intended order of script execution for iptables setup is:"
echo "   1. Basic NAT/Forwarding (e.g., scripts/setup_hotspot_nat.sh)"
echo "   2. Captive Portal HTTP Redirect (this script: scripts/setup_captive_portal_redirect.sh)"
echo "   3. Squid Proxy Redirect (e.g., scripts/redirect_to_squid.sh)"
echo ""
echo "To make these rules persistent across reboots (after confirming functionality):"
echo "   sudo apt-get install -y iptables-persistent"
echo "   sudo netfilter-persistent save"
echo "   (Or if already installed: sudo netfilter-persistent save)"
echo ""
echo "To view PREROUTING rules in nat table: sudo iptables -t nat -L PREROUTING -v -n --line-numbers"
echo "To view INPUT rules: sudo iptables -L INPUT -v -n --line-numbers"
echo "Captive portal redirection setup complete."
