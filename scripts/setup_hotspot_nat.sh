#!/bin/bash
# Script to enable NAT and IP forwarding for the Chernarus_Beacon hotspot

# Variables
WLAN_IF="wlan0"       # Hotspot interface
ETH_IF="eth0"         # Internet-connected interface (user may need to change this if using e.g. wlan1 for internet)
HOTSPOT_NET="192.168.73.0/24"
RPI_WLAN_IP="192.168.73.1"    # RPi's IP on wlan0, crucial for services hosted on the Pi itself

echo "Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1

echo "Configuring iptables for NAT..."
# It's generally safer not to flush all rules automatically.
# The user can do this manually if a clean slate is needed.
# echo "Flushing existing rules (optional, use with caution)..."
# sudo iptables -F
# sudo iptables -t nat -F

echo "Allowing forwarding between $WLAN_IF and $ETH_IF..."
# Allow all traffic forwarding from hotspot clients ($WLAN_IF) to the internet ($ETH_IF).
# This provides general internet access. It can be further restricted if specific
# outbound policies are required (e.g., allowing only HTTP/HTTPS).
sudo iptables -A FORWARD -i $WLAN_IF -o $ETH_IF -j ACCEPT
# Allow established and related connections back to the hotspot
sudo iptables -A FORWARD -i $ETH_IF -o $WLAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "Applying NAT (Masquerade) rule for traffic from $HOTSPOT_NET via $ETH_IF..."
# NAT rule: Masquerade traffic from hotspot network to $ETH_IF
sudo iptables -t nat -A POSTROUTING -s $HOTSPOT_NET -o $ETH_IF -j MASQUERADE

# ======================================================================
# Optional INPUT rules for services on the Raspberry Pi itself (listening on wlan0)
# Uncomment these if you are running services like SSH, DNS, DHCP directly on the Pi
# and want them accessible from the hotspot clients.
# Pi-hole (dnsmasq) will need DHCP and DNS.
# These rules assume the RPi itself is $RPI_WLAN_IP.
# ======================================================================
echo "Adding INPUT rules for essential services on $RPI_WLAN_IP ($WLAN_IF)..."
# DHCP (dnsmasq via Pi-hole)
sudo iptables -A INPUT -i $WLAN_IF -p udp --dport 67 -d $RPI_WLAN_IP -j ACCEPT  # DHCP Server
# DNS (Pi-hole)
sudo iptables -A INPUT -i $WLAN_IF -p udp --dport 53 -d $RPI_WLAN_IP -j ACCEPT  # DNS (Pi-hole)
sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport 53 -d $RPI_WLAN_IP -j ACCEPT  # DNS (Pi-hole)
# Captive Portal (Nginx on Chernarus_Entrypoint)
sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport 8080 -d $RPI_WLAN_IP -j ACCEPT # Captive Portal (Nginx)

# Example: Allow SSH access to the RPi from the hotspot network
# sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport 22 -s $HOTSPOT_NET -d $RPI_WLAN_IP -j ACCEPT

# Optional: Allow access to Pi-hole Admin UI from hotspot clients
# By default, the Pi-hole admin interface (port 8081 on $RPI_WLAN_IP) is only accessible
# if this rule is uncommented. Consider security implications before enabling.
# sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport 8081 -d $RPI_WLAN_IP -j ACCEPT # Pi-hole Admin UI (uncomment if access from hotspot clients is desired)

echo ""
echo "NAT and forwarding configuration complete."
echo "The internet-facing interface is assumed to be $ETH_IF. If it's different (e.g. usb0, wlan1), please edit this script."
echo "To make these firewall rules persistent across reboots, you need to install 'iptables-persistent'."
echo "Run: sudo apt-get update && sudo apt-get install -y iptables-persistent"
echo "During the installation, you will be asked to save current IPv4 and IPv6 rules. Answer 'yes' for IPv4."
echo "If you modify the rules later (e.g., by re-running this script or other scripts like redirect_to_squid.sh), update the saved rules with:"
echo "sudo netfilter-persistent save"
echo "or"
echo "sudo dpkg-reconfigure iptables-persistent"
echo "Remember to save rules after running this script AND other scripts (like redirect_to_squid.sh or setup_captive_portal_redirect.sh) if you run them separately."
