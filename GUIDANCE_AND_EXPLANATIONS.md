# "Chernarus Beacon" Hotspot: OS-Level Configuration Guide (Raspberry Pi 5)

This guide details the host Operating System level configuration for the Wi-Fi hotspot component (`Chernarus_Beacon`) of the "Chernarus Beacon" (Operación: The Perimeter) project. It focuses on setting up `hostapd` and the underlying network interface configuration on the Raspberry Pi 5, assuming Arch Linux. The hotspot will operate on the `192.168.73.0/24` network, with the Raspberry Pi itself at `192.168.73.1` on the `wlan0` interface.

Dockerized services like the DHCP server, DNS (Pi-hole), Squid proxy, and Captive Portal are managed via the main `docker-compose.yml` as described in other documents (e.g., main `README.md` and specific wiki pages).

## Generated Configuration Files:

1.  **`hotspot_config/hostapd.conf`**: Configuration for `hostapd`, the software that creates the wireless access point.
2.  **`hotspot_config/dhcp/dhcpd.conf`**: Configuration for the dedicated DHCP server container (`networkboot/dhcpd`) that assigns IP addresses to devices connecting to the hotspot.
3.  **`scripts/setup_hotspot_nat.sh`**: A shell script to configure Network Address Translation (NAT) and IP forwarding, allowing hotspot clients to access the internet through the Raspberry Pi's other network connection (e.g., `eth0`).
4.  **`hotspot_config/pihole_custom_dnsmasq.conf`**: (Deprecated for DHCP) This file was previously used for configuring Pi-hole's internal `dnsmasq` for hotspot DHCP. With the dedicated `dhcp_server` container, this file is no longer used for DHCP.

## I. `hostapd` Configuration (Access Point Setup)

The `hotspot_config/hostapd.conf` file configures the basic parameters of your Wi-Fi hotspot.

**Key Settings:**

*   **`ssid=rpi`**: The name of the Wi-Fi network that will be broadcast.
*   **`wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE`**: The password for the Wi-Fi network. **This is a placeholder and MUST be changed.**
*   **`country_code=US`**: The regulatory domain for wireless communication.

**Deployment Steps:**

1.  **IMPORTANT: Change the Wi-Fi Password!**
    Open `hotspot_config/hostapd.conf`. The line `wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE` is a placeholder.
    You **must** change this to a strong, unique password. Refer to the 'Important: Initial Security Setup' section in the main `README.md` or the `SECURITY.md` file for more details on secure credential management and choosing strong passwords.

2.  **Verify Country Code:**
    In `hotspot_config/hostapd.conf`, check and update the `country_code` (e.g., `GB` for the United Kingdom, `DE` for Germany) to match your physical location. This is important for regulatory compliance. The file provided in the repository defaults to `US`.

3.  **Install `hostapd` (Arch Linux):**
    If not already installed, open a terminal on your Raspberry Pi and run:
    ```bash
    sudo pacman -Syu --needed hostapd
    ```

4.  **Copy the Configuration File:**
    Copy the modified `hostapd.conf` file to the `/etc/hostapd/` directory on your Raspberry Pi:
    ```bash
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    ```

5.  **Inform `hostapd` where to find the configuration (Arch Linux):**
    On Arch Linux, `/etc/default/hostapd` is not typically used. The `hostapd.service` unit file usually expects the configuration at `/etc/hostapd/hostapd.conf` by default. If you've placed the file there, no further action is needed for `hostapd` to find its configuration. If you needed to specify a different path, you would typically override the systemd service file for `hostapd`.

6.  **Unmask and Enable `hostapd` Service:**
    It's common for `hostapd` to be masked by default.
    ```bash
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    ```
    You will start `hostapd` later, after configuring networking and DHCP.

## II. DHCP Server Configuration (via Dedicated Docker Container)

**Explanation:**
The hotspot uses a dedicated Docker container running the `networkboot/dhcpd` image to manage IP address assignments for clients connecting to the `wlan0` network (`192.168.73.0/24`). This approach isolates DHCP services from Pi-hole's internal `dnsmasq` instance, providing a more modular setup.

**Configuration File:**
The primary configuration for this DHCP server is located at `hotspot_config/dhcp/dhcpd.conf`. This file defines crucial parameters such as the IP address range, lease times, the gateway (router) IP, and the DNS server(s) provided to hotspot clients.

Here's an example snippet of what this configuration file might contain:
```conf
# Example snippet from hotspot_config/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
authoritative; # This DHCP server is the authoritative source for this subnet.

subnet 192.168.73.0 netmask 255.255.255.0 {
  range 192.168.73.10 192.168.73.200;
  option routers 192.168.73.1;               # Gateway for clients (RPi's wlan0 IP)
  option domain-name-servers 192.168.73.1;  # DNS server (Pi-hole's IP)
  # option domain-name "chernarus.local";    # Optional: local domain name
}
```
You should review `hotspot_config/dhcp/dhcpd.conf` and customize it if your network requirements differ (e.g., different IP range, lease times).

**Docker Compose Service (`dhcp_server`):**
The DHCP server is defined as the `dhcp_server` service in the main `docker-compose.yml` file located at the root of the project. Key aspects of its configuration include:

*   **`image: networkboot/dhcpd`**: Specifies the Docker image used for the DHCP server.
*   **`network_mode: "host"`**: This is a critical setting. It allows the DHCP server container to directly use the host's network stack. This is necessary because DHCP requests from clients are broadcast packets, and the server needs to listen on and respond via the physical `wlan0` interface. While this reduces container network isolation, it's a common and often necessary configuration for DHCP servers running in Docker to interact correctly with the LAN.
*   **`volumes: - ./hotspot_config/dhcp/dhcpd.conf:/data/dhcpd.conf`**: This line maps the `dhcpd.conf` file from your host system into the container where the DHCP server software expects it. The exact path inside the container (`/data/dhcpd.conf`) depends on the `networkboot/dhcpd` image.
*   **`command: ["-cf", "/data/dhcpd.conf", "-f", "wlan0"]`**: This command starts the DHCP server inside the container.
    *   `-cf /data/dhcpd.conf`: Specifies the configuration file to use.
    *   `-f`: Runs the server in the foreground (common for containers).
    *   `wlan0`: Instructs the DHCP server to listen for requests on the `wlan0` interface. **Ensure `wlan0` is the correct interface name for your hotspot.**
*   **`cap_add: [NET_ADMIN, NET_RAW]`**: These capabilities grant the container necessary privileges for DHCP operations, such as interacting with network interfaces and using raw sockets.

**Pi-hole and DNS:**
It's important to understand the roles here:
*   The **`dhcp_server` container** (using `networkboot/dhcpd`) is responsible for **assigning IP addresses** to clients on the hotspot.
*   **Pi-hole** (running in its own Docker container) serves as the **DNS server** for these clients.
The `dhcp_server` is configured to tell clients (via `option domain-name-servers 192.168.73.1;` in `dhcpd.conf`) to use Pi-hole's IP address (`192.168.73.1`) for resolving domain names.

**Deprecation of `pihole_custom_dnsmasq.conf`:**
With the dedicated `dhcp_server` container now managing DHCP for the hotspot, the file `hotspot_config/pihole_custom_dnsmasq.conf` (which was previously used to configure Pi-hole's internal `dnsmasq` for hotspot DHCP) **is no longer used for this setup**. You can ignore this file or remove it from your `/etc/dnsmasq.d/` directory on the Raspberry Pi to avoid confusion. Pi-hole will continue to function as a DNS server based on its primary configuration.

## III. Network Configuration (Static IP for `wlan0` and NAT)

Before starting `hostapd`, you need to assign a static IP address to the `wlan0` interface. This IP (`192.168.73.1`) will be the gateway for your hotspot clients.

**Static IP for `wlan0`:**
The `wlan0` interface requires a static IP address (`192.168.73.1/24`) to serve as the gateway for hotspot clients.
There are several ways to configure this on Arch Linux:

*   **Using `systemd-networkd` (Recommended for this project):**
    This is the method generally preferred in the project's wiki (`[[06-Configurar-Hotspot]]`). It involves creating a `.network` file in `/etc/systemd/network/` (e.g., `30-hotspot-wlan0.network`) to define the static IP for `wlan0` and ensuring NetworkManager is configured to ignore `wlan0`.
    Example for `/etc/systemd/network/30-hotspot-wlan0.network`:
    ```ini
    [Match]
    Name=wlan0

    [Network]
    Address=192.168.73.1/24
    # IPForward=yes # Optional: IP forwarding can also be enabled here or via sysctl
    ```
    Then enable and start `systemd-networkd` and `systemd-resolved` (if not already running), and disable/configure NetworkManager to ignore `wlan0`.

*   **Using `dhcpcd` (Alternative):**
    If you prefer to use `dhcpcd` (common on Raspberry Pi OS, but less integrated with the Arch Linux default networking stack if `systemd-networkd` is active):
    1.  Edit the `dhcpcd` configuration file:
        ```bash
        sudo nano /etc/dhcpcd.conf
        ```
    2.  Add the following lines to the end of the file. If you have other `interface wlan0` configurations, ensure they don't conflict.
        ```conf
        interface wlan0
        static ip_address=192.168.73.1/24
        #nohook wpa_supplicant # Optional: if you want to manage wlan0 entirely via hostapd and not system networking.
                               # For a dedicated hotspot, this is often a good idea.
        ```
    3.  Save and exit.
    4.  Restart `dhcpcd`: `sudo systemctl restart dhcpcd`.

*   **Manual IP assignment (Temporary, for testing):**
    ```bash
    sudo ip link set dev wlan0 down
    sudo ip addr add 192.168.73.1/24 dev wlan0
    sudo ip link set dev wlan0 up
    ```
Whichever method you choose, verify with `ip addr show wlan0` that `wlan0` has the IP `192.168.73.1/24` before starting `hostapd`. The `[[06-Configurar-Hotspot]]` wiki page provides more detailed guidance on using `systemd-networkd`.

**NAT and IP Forwarding (`scripts/setup_hotspot_nat.sh`):**

This script enables the Raspberry Pi to act as a router, forwarding traffic from the Wi-Fi hotspot clients (`wlan0`) to your main internet connection (assumed to be `eth0`).

1.  **Review Internet Interface:**
    The script defaults to using `eth0` as the internet-connected interface (`ETH_IF="eth0"`). If your Raspberry Pi gets its internet connection from a different interface (e.g., `usb0`, or another Wi-Fi adapter like `wlan1`), **you must edit `scripts/setup_hotspot_nat.sh` and change the `ETH_IF` variable** to match your setup.

2.  **Make the Script Executable:**
    Navigate to the directory where you cloned the repository.
    ```bash
    chmod +x scripts/setup_hotspot_nat.sh
    ```

3.  **Run the Script:**
    Execute the script with superuser privileges:
    ```bash
    sudo ./scripts/setup_hotspot_nat.sh
    ```
    This will enable IP forwarding and set up the necessary `iptables` rules. The script includes rules to allow DHCP and DNS traffic to the Pi itself on `wlan0`. The DHCP rule (UDP port 67) allows clients to reach the `Hotspot_DHCP_Server` container (running in `network_mode: host`), and the DNS rules (TCP/UDP port 53) allow clients to reach the Pi-hole container for DNS resolution.

4.  **Make Firewall Rules Persistent:**
    The `iptables` rules set by the script are temporary and will be lost on reboot. To make them persistent:
    *   **For Debian/Ubuntu based systems (like Raspberry Pi OS):**
        ```bash
        sudo apt-get update && sudo apt-get install -y iptables-persistent
        # During the installation, you will be asked if you want to save current IPv4 and IPv6 rules.
        # Answer Yes for IPv4. You can answer No for IPv6 if you are not using it.
        # If you modify the firewall rules later, save them again:
        sudo netfilter-persistent save
        ```
    *   **For Arch Linux based systems:**
        `iptables-nft` is commonly used, providing the `iptables` command interface with an `nftables` backend, and includes services for persistence.
        ```bash
        # For Arch Linux, iptables-nft provides the modern iptables interface
        # and includes services for persistence.
        sudo pacman -Syu iptables-nft
        sudo systemctl enable iptables.service # To save rules on shutdown/load on boot
        sudo systemctl enable ip6tables.service # If using IPv6 rules (optional)
        # Then save rules using:
        sudo iptables-save > /etc/iptables/iptables.rules
        # If using IPv6:
        # sudo ip6tables-save > /etc/iptables/ip6tables.rules
        ```
        **Note:** The exact package and commands for `iptables` persistence can vary slightly on Arch Linux depending on whether you are using the `nftables` backend (common) or legacy `iptables`, and which helper utilities you prefer (e.g., `systemd` services vs. older scripts). The `iptables-nft` with `systemd` services is a common modern approach. Always consult the [Arch Wiki for iptables](https://wiki.archlinux.org/title/Iptables) and [nftables](https://wiki.archlinux.org/title/Nftables) for the most current practices.
    *   If you modify the firewall rules later (e.g., by re-running the `setup_hotspot_nat.sh` script or other scripts like `redirect_to_squid.sh`), remember to save them again using the appropriate method for your system. Ensure you save after all relevant scripts (`setup_hotspot_nat.sh`, `setup_captive_portal_redirect.sh`, `redirect_to_squid.sh`) have been run.

## IV. Starting and Testing the Hotspot

1.  **Reboot (Recommended):**
    After all configurations, it's often best to reboot the Raspberry Pi to ensure all services start in the correct order with the new settings.
    ```bash
    sudo reboot
    ```

2.  **If you didn't reboot, start `hostapd` manually (first time):**
    ```bash
    sudo systemctl start hostapd
    ```

3.  **Check Service Status:**
    After rebooting or starting, check the status of the services:
    ```bash
    sudo systemctl status hostapd  # Should be active (running)
    docker ps                     # Should list 'Hotspot_DHCP_Server', 'Pihole_DNS_Filter', etc. as 'Up'
    ip addr show wlan0            # Should show 192.168.73.1/24
    ```
    Look for `hostapd` being active and `wlan0` having the IP `192.168.73.1`. Verify that the `Hotspot_DHCP_Server` container is running.

4.  **Test the Hotspot:**
    *   On another device (laptop, phone), search for Wi-Fi networks.
    *   You should see the network named `rpi` (or whatever you set as `ssid`).
    *   Connect to it using the password you set.
    *   Your device should receive an IP address in the `192.168.73.10` - `192.168.73.200` range.
    *   Try browsing the internet. Traffic should be routed through the Raspberry Pi, and DNS queries should be handled by Pi-hole. You can check Pi-hole's query log to confirm.

## Troubleshooting Tips:

*   **`rfkill`**: If `wlan0` is blocked, use `sudo rfkill unblock wifi` or `sudo rfkill unblock all`.
*   **`hostapd` fails to start**:
    *   Check `sudo systemctl status hostapd` and `journalctl -u hostapd` for error messages.
    *   Ensure `wlan0` is not already in use or configured in client mode by other networking services (e.g. NetworkManager or wpa_supplicant if not properly configured for AP mode). The `nohook wpa_supplicant` line in `dhcpcd.conf` for `wlan0` can help prevent conflicts.
    *   Verify the `country_code` in `hostapd.conf` is valid.
*   **No IP address on client devices**:
    *   Ensure the `Hotspot_DHCP_Server` Docker container is running (`docker ps`). Check its logs for errors: `docker logs Hotspot_DHCP_Server`.
    *   Verify that `hotspot_config/dhcp/dhcpd.conf` is correctly configured and that the `dhcp_server` service in `docker-compose.yml` correctly references `wlan0` in its command.
    *   Verify the `iptables` rules for DHCP (port 67 UDP) are present and correctly allow traffic to `$RPI_WLAN_IP` (e.g., `sudo iptables -L INPUT -v -n --line-numbers`). The `setup_hotspot_nat.sh` script should handle this.
*   **No internet on client devices**:
    *   Double-check the `ETH_IF` variable in `setup_hotspot_nat.sh` matches your actual internet-providing interface.
    *   Ensure IP forwarding is enabled: `cat /proc/sys/net/ipv4/ip_forward` (should be `1`).
    *   Verify the `iptables` NAT and FORWARD rules: `sudo iptables -t nat -L -v -n --line-numbers` and `sudo iptables -L FORWARD -v -n --line-numbers`.
    *   Check DNS settings on the client – it should be `192.168.73.1`.

This completes the setup for your Chernarus_Beacon Wi-Fi hotspot!
