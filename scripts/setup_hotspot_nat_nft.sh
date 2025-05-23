#!/bin/bash

# === Configuration ===
# Network interface connected to the internet (WAN)
# IMPORTANT: User MUST verify and change this to their actual Ethernet interface
ETH_IF="eth0"

# Network interface for the Wi-Fi Hotspot (LAN)
# IMPORTANT: User MUST verify and change this to their actual WLAN interface
WLAN_IF="wlan0"

# Subnet for the Wi-Fi Hotspot
HOTSPOT_NET="192.168.73.0/24"

# === Script Start ===
echo "Starting Hotspot NAT and Firewall Setup using nftables..."

# 1. Enable IP Forwarding
echo "[INFO] Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to enable IP forwarding. Exiting."
    exit 1
fi

# 2. Define nftables ruleset
# Note: We will pipe this directly to nft.
# For saving to a file, you would redirect this heredoc to a file.
NFT_RULES=$(cat <<EOF
# Flush all existing rules
flush ruleset

# === INET TABLE: firewall_table ===
# This table handles general packet filtering.
table inet firewall_table {
    # --- INPUT CHAIN ---
    # Handles incoming traffic to the Raspberry Pi itself.
    # Default policy is DROP for security.
    chain input {
        type filter hook input priority 0; policy drop;

        # Accept traffic from the loopback interface
        iifname "lo" accept comment "Accept loopback traffic"

        # Accept established and related connections
        ct state established,related accept comment "Accept established/related connections"

        # Allow DHCP requests from clients on the WLAN interface
        iifname "\$WLAN_IF" udp dport 67 accept comment "Allow DHCP from WLAN"

        # Allow DNS requests from clients on the WLAN interface (UDP and TCP)
        iifname "\$WLAN_IF" udp dport 53 accept comment "Allow DNS (UDP) from WLAN"
        iifname "\$WLAN_IF" tcp dport 53 accept comment "Allow DNS (TCP) from WLAN"

        # Optional: Allow SSH access to the Pi from the WLAN interface (if needed for management)
        # iifname "\$WLAN_IF" tcp dport 22 accept comment "Allow SSH from WLAN"
    }

    # --- FORWARD CHAIN ---
    # Handles traffic passing through the Raspberry Pi (e.g., from WLAN to ETH).
    # Default policy is DROP.
    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow traffic from WLAN to ETH (hotspot clients to internet)
        iifname "\$WLAN_IF" oifname "\$ETH_IF" accept comment "Forward WLAN to ETH"

        # Allow established and related traffic back from ETH to WLAN
        iifname "\$ETH_IF" oifname "\$WLAN_IF" ct state established,related accept comment "Forward established/related ETH to WLAN"
    }
}

# === IP TABLE: nat_table ===
# This table handles Network Address Translation (NAT).
# We use 'ip' for NAT as 'inet' NAT is less common for simple masquerade.
table ip nat_table {
    # --- POSTROUTING CHAIN ---
    # Handles traffic just before it leaves an interface.
    # Used for Source NAT (SNAT/Masquerade).
    chain postrouting {
        type nat hook postrouting priority 100; # NF_IP_PRI_NAT_SRC

        # Masquerade (NAT) traffic from the hotspot network going out the ETH interface
        ip saddr \$HOTSPOT_NET oifname "\$ETH_IF" masquerade comment "Masquerade hotspot traffic to ETH"
    }
}
EOF
)

# Substitute shell variables into the ruleset string
# We need to be careful with escaping for sed and variable expansion
NFT_RULES_SUBST=$(echo "$NFT_RULES" | \
    sed "s/\\\$WLAN_IF/$WLAN_IF/g; s/\\\$ETH_IF/$ETH_IF/g; s/\\\$HOTSPOT_NET/$HOTSPOT_NET/g")

# 3. Apply nftables ruleset
echo "[INFO] Applying nftables ruleset..."
echo "${NFT_RULES_SUBST}" | sudo nft -f -
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to apply nftables ruleset. Exiting."
    # Display the rules that were attempted, for debugging
    echo "--- Attempted Ruleset ---"
    echo "${NFT_RULES_SUBST}"
    echo "-------------------------"
    exit 1
fi

echo "[SUCCESS] nftables ruleset applied successfully."

# 4. User Guidance for Persistence
echo ""
echo "=== IMPORTANT NEXT STEPS ==="
echo "1. VERIFY INTERFACES:"
echo "   The script used ETH_IF='${ETH_IF}' and WLAN_IF='${WLAN_IF}'."
echo "   If these are incorrect, please edit this script and re-run it."
echo "   You can find your interface names using 'ip a' or 'ifconfig'."
echo ""
echo "2. PERSISTENCE (Making rules survive reboots):"
echo "   The current rules are temporary and will be lost on reboot."
echo "   To make them permanent:"
echo "   a. Ensure nftables is installed: 'sudo apt update && sudo apt install nftables -y'"
echo "   b. Save the current (working) ruleset:"
echo "      sudo nft list ruleset > /etc/nftables.conf"
echo "      (This command overwrites /etc/nftables.conf. Review existing content if any.)"
echo "   c. Enable the nftables service to load rules at boot:"
echo "      sudo systemctl enable nftables.service"
echo "      sudo systemctl start nftables.service"
echo ""
echo "3. CHECK STATUS:"
echo "   sudo nft list ruleset"
echo "   sudo systemctl status nftables.service"
echo ""
echo "Setup complete. Your hotspot NAT and firewall should now be active."
echo "Remember to configure your DHCP server (e.g., dnsmasq or isc-dhcp-server)"
echo "to serve addresses on the ${WLAN_IF} interface in the ${HOTSPOT_NET} range,"
echo "and to provide this Raspberry Pi's ${WLAN_IF} IP as the gateway and DNS server."

exit 0
