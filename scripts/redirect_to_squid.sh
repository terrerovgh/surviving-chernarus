#!/bin/bash
# Script to redirect HTTP/HTTPS traffic from hotspot clients to Berezino_Checkpoint (Squid)

# Variables
WLAN_IF="wlan0"                 # Hotspot interface
HOTSPOT_NET="192.168.73.0/24"   # Hotspot network
SQUID_HTTP_PORT="3128"          # Squid's HTTP listening port (from squid.conf http_port)
SQUID_HTTPS_PORT="3129"         # Squid's HTTPS listening port (from squid.conf https_port)
RPI_WLAN_IP="192.168.73.1"      # RPi's IP on wlan0

echo "Configuring iptables to redirect traffic from $WLAN_IF to Squid..."

# === PREROUTING rules for traffic originating from hotspot clients ===

# --- IMPORTANT: Traffic to the Raspberry Pi itself on wlan0 should NOT be redirected ---
# This includes DNS (port 53 to Pi-hole/192.168.73.1), DHCP (port 67/68),
# and potentially a captive portal hosted on the RPi (e.g. on port 80/443 on 192.168.73.1).
# The DNAT rules below will use -d ! $RPI_WLAN_IP to avoid this loop for traffic destined
# for the Pi itself. However, for true transparent proxying of traffic *through* the Pi,
# this is tricky.
# A common approach for transparent proxying is to apply redirection on the FORWARD chain for traffic
# passing *through* the Pi, or on PREROUTING for traffic originated *from* the Pi (not the case here for clients).
# For traffic from clients on wlan0 destined for the internet:
# The DNAT rules on PREROUTING are appropriate.

echo "Ensuring traffic directly to $RPI_WLAN_IP (e.g., DNS, Captive Portal) is NOT redirected..."
# Allow traffic destined for the Pi-hole/RPi itself on wlan0 to bypass redirection
# This is critical for DNS, DHCP, and the captive portal access.
sudo iptables -t nat -A PREROUTING -i $WLAN_IF -d $RPI_WLAN_IP -p tcp -m multiport --dports 80,443 -j RETURN
sudo iptables -t nat -A PREROUTING -i $WLAN_IF -d $RPI_WLAN_IP -p udp -m multiport --dports 53,67,68 -j RETURN


echo "Redirecting HTTP traffic (port 80) from $HOTSPOT_NET (excluding to $RPI_WLAN_IP) to Squid port $SQUID_HTTP_PORT..."
sudo iptables -t nat -A PREROUTING -i $WLAN_IF -s $HOTSPOT_NET -p tcp --dport 80 -d ! $RPI_WLAN_IP -j DNAT --to-destination 127.0.0.1:$SQUID_HTTP_PORT

echo "Redirecting HTTPS traffic (port 443) from $HOTSPOT_NET (excluding to $RPI_WLAN_IP) to Squid port $SQUID_HTTPS_PORT..."
sudo iptables -t nat -A PREROUTING -i $WLAN_IF -s $HOTSPOT_NET -p tcp --dport 443 -d ! $RPI_WLAN_IP -j DNAT --to-destination 127.0.0.1:$SQUID_HTTPS_PORT

# === Allowing Squid Traffic ===
# If the INPUT policy is DROP, you might need to explicitly allow traffic to Squid's ports.
# However, Docker typically manages its own rules for exposing container ports.
# The DOCKER chain in the nat table and FORWARD chain usually handle this.
# For traffic originating from clients and DNATed to 127.0.0.1 (host),
# the host's INPUT chain will see it.
echo "Ensuring host can accept traffic to Squid ports (if INPUT policy is not ACCEPT)..."
sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport $SQUID_HTTP_PORT -s $HOTSPOT_NET -d 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -i $WLAN_IF -p tcp --dport $SQUID_HTTPS_PORT -s $HOTSPOT_NET -d 127.0.0.1 -j ACCEPT

# If Squid container is on a custom Docker network and not using host networking,
# ensure FORWARD rules from wlan0 to that Docker bridge are in place.
# The previous setup_hotspot_nat.sh should allow general forwarding from wlan0 to other interfaces
# (like docker0 or other bridge). The -o $ETH_IF in that script might need adjustment if
# Docker traffic doesn't exit via $ETH_IF directly (though usually it does after SNAT).

echo ""
echo "Redirection rules applied."
echo "Verify with: sudo iptables -t nat -L PREROUTING -v -n"
echo "And: sudo iptables -L INPUT -v -n"
echo "Remember to make these rules persistent using iptables-persistent:"
echo "sudo netfilter-persistent save"
echo ""
echo "IMPORTANT: Ensure your Raspberry Pi's firewall (INPUT/FORWARD chains) allows this redirected traffic"
echo "and allows Squid to make outbound connections to the internet (usually via $ETH_IF or similar)."
echo "The setup_hotspot_nat.sh script should generally cover outbound, but review if issues arise."
