# Wi-Fi Hotspot (Chernarus_Beacon) Setup Guide for Raspberry Pi 5

This guide provides instructions for setting up a Wi-Fi hotspot named `rpi` (internally referred to as `Chernarus_Beacon` for thematic purposes) on your Raspberry Pi 5 using the generated configuration files. The hotspot will operate on the `192.168.73.0/24` network, with the Raspberry Pi itself at `192.168.73.1` on the `wlan0` interface.

## Generated Configuration Files:

1.  **`hotspot_config/hostapd.conf`**: Configuration for `hostapd`, the software that creates the wireless access point.
2.  **`hotspot_config/pihole_custom_dnsmasq.conf`**: DHCP configuration for `dnsmasq` (managed by Pi-hole) to assign IP addresses to devices connecting to the hotspot.
3.  **`scripts/setup_hotspot_nat.sh`**: A shell script to configure Network Address Translation (NAT) and IP forwarding, allowing hotspot clients to access the internet through the Raspberry Pi's other network connection (e.g., `eth0`).

## I. `hostapd` Configuration (Access Point Setup)

The `hotspot_config/hostapd.conf` file configures the basic parameters of your Wi-Fi hotspot.

**Key Settings:**

*   **`ssid=rpi`**: The name of the Wi-Fi network that will be broadcast.
*   **`wpa_passphrase=YourStrongPasswordHere`**: The password for the Wi-Fi network.
*   **`country_code=US`**: The regulatory domain for wireless communication.

**Deployment Steps:**

1.  **IMPORTANT: Change the Wi-Fi Password!**
    Open `hotspot_config/hostapd.conf` and change `wpa_passphrase=YourStrongPasswordHere` to a strong, unique password.

2.  **Verify Country Code:**
    In `hotspot_config/hostapd.conf`, check and update the `country_code` (e.g., `GB` for the United Kingdom, `DE` for Germany) to match your physical location. This is important for regulatory compliance.

3.  **Install `hostapd`:**
    If not already installed, open a terminal on your Raspberry Pi and run:
    ```bash
    sudo apt-get update
    sudo apt-get install -y hostapd
    ```

4.  **Copy the Configuration File:**
    Copy the modified `hostapd.conf` file to the `/etc/hostapd/` directory on your Raspberry Pi:
    ```bash
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    ```

5.  **Inform `hostapd` where to find the configuration:**
    Edit the `hostapd` default configuration file:
    ```bash
    sudo nano /etc/default/hostapd
    ```
    Find the line `#DAEMON_CONF=""` and change it to:
    ```
    DAEMON_CONF="/etc/hostapd/hostapd.conf"
    ```
    Save and exit the editor.

6.  **Unmask and Enable `hostapd` Service:**
    It's common for `hostapd` to be masked by default.
    ```bash
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    ```
    You will start `hostapd` later, after configuring networking and DHCP.

## II. DHCP Server Configuration (via Pi-hole/dnsmasq)

**DHCP Choice Explanation:**

For thematic consistency with `StarySobor_RadioPost` (your Pi-hole instance) and to centralize DNS and IP management, these instructions integrate DHCP services for the hotspot directly into Pi-hole. Pi-hole uses `dnsmasq` internally, which is a lightweight DHCP and DNS caching server. By adding a custom configuration file to Pi-hole's `dnsmasq` setup, we can make Pi-hole responsible for assigning IP addresses to devices connecting to the `Chernarus_Beacon` hotspot (`wlan0`). This avoids running a separate DHCP server and ensures that hotspot clients can easily use Pi-hole for DNS.

**Deployment Steps for `pihole_custom_dnsmasq.conf`:**

1.  **Copy the Custom `dnsmasq` Configuration:**
    Place the generated `hotspot_config/pihole_custom_dnsmasq.conf` file into the `/etc/dnsmasq.d/` directory on your Raspberry Pi (the one running Pi-hole). It's good practice to give it a descriptive name, for example:
    ```bash
    sudo cp hotspot_config/pihole_custom_dnsmasq.conf /etc/dnsmasq.d/02-chernarus-hotspot-dhcp.conf
    ```
    (The `02-` prefix helps with ordering if you have multiple custom files).

2.  **Restart Pi-hole's FTLDNS Service:**
    This will make `dnsmasq` pick up the new configuration.
    ```bash
    sudo pihole restartdns
    # OR, if the above command is not found or you prefer systemctl:
    # sudo systemctl restart pihole-FTL.service
    ```

3.  **Pi-hole `setupVars.conf` Check (Important):**
    Ensure Pi-hole's main configuration (`/etc/pihole/setupVars.conf`) does **not** define `PIHOLE_INTERFACE` in a way that would conflict. For example, if `PIHOLE_INTERFACE` is set strictly to `eth0`, Pi-hole might not listen for DHCP requests on `wlan0` even with the custom config.
    *   The `interface=wlan0` line within your `02-chernarus-hotspot-dhcp.conf` is intended to explicitly tell `dnsmasq` to listen on `wlan0` for DHCP (and DNS) queries for the hotspot.
    *   If you have `PIHOLE_INTERFACE` set in `setupVars.conf`, and it's *not* set to listen on all interfaces (e.g., `PIHOLE_INTERFACE=`), you might need to remove that specific line or adjust it if issues arise. Often, for Pi-hole to serve DHCP on multiple interfaces, it's best to let `dnsmasq.d` configurations handle the interface specifics.

4.  **Verify in Pi-hole Admin Interface:**
    *   Navigate to your Pi-hole's admin web interface.
    *   Go to **Settings > DHCP**.
    *   Check if the "DHCP server enabled" box is ticked.
    *   You should see the DHCP range `192.168.73.10` to `192.168.73.200` listed, and it should indicate it's active for `wlan0`.
    *   If it wasn't previously enabled, or if settings don't appear, you might need to:
        *   Enable the DHCP server using the Pi-hole GUI.
        *   If it was already enabled for another interface (e.g., `eth0`), the new configuration should add `wlan0` to its scope. A restart of FTLDNS (`pihole restartdns`) is usually sufficient.
        *   Ensure "Pi-hole DHCP server" is selected under "DHCP Settings" if you are using Pi-hole as the DHCP server for your main network as well.

## III. Network Configuration (Static IP for `wlan0` and NAT)

Before starting `hostapd`, you need to assign a static IP address to the `wlan0` interface. This IP (`192.168.73.1`) will be the gateway for your hotspot clients.

**Static IP for `wlan0` (using `dhcpcd`):**

Most Raspberry Pi OS versions use `dhcpcd` to manage network interfaces.

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
                           # If you use wlan0 for client mode sometimes, don't add this.
    ```

3.  Save and exit.

4.  Restart `dhcpcd` to apply the changes (or reboot the Pi):
    ```bash
    sudo systemctl restart dhcpcd
    ```
    Verify with `ip addr show wlan0` that it has the IP `192.168.73.1`.

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
    This will enable IP forwarding and set up the necessary `iptables` rules. The script includes rules to allow DHCP and DNS traffic to the Pi itself on `wlan0`, which are needed for Pi-hole/dnsmasq to function for hotspot clients.

4.  **Make Firewall Rules Persistent:**
    The `iptables` rules set by the script are temporary and will be lost on reboot. To make them persistent:
    *   Install `iptables-persistent`:
        ```bash
        sudo apt-get update && sudo apt-get install -y iptables-persistent
        ```
    *   During the installation, you will be asked if you want to save current IPv4 and IPv6 rules. Answer **Yes** for IPv4. You can answer No for IPv6 if you are not using it.
    *   If you modify the firewall rules later (e.g., by re-running the `setup_hotspot_nat.sh` script or making manual changes), you must save them again:
        ```bash
        sudo netfilter-persistent save
        # Alternatively, reconfigure the package:
        # sudo dpkg-reconfigure iptables-persistent
        ```

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
    sudo systemctl status hostapd
    sudo systemctl status pihole-FTL.service # or dnsmasq if you inspect it directly
    ip addr show wlan0
    ```
    Look for `hostapd` being active and `wlan0` having the IP `192.168.73.1`.

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
    *   Ensure `pihole-FTL.service` (dnsmasq) is running and configured correctly for `wlan0`. Check `/var/log/pihole-FTL.log` or `/var/log/daemon.log` / `/var/log/syslog` for dnsmasq errors.
    *   Verify the `iptables` rules for DHCP (port 67) are present (`sudo iptables -L INPUT -v -n --line-numbers`).
*   **No internet on client devices**:
    *   Double-check the `ETH_IF` variable in `setup_hotspot_nat.sh` matches your actual internet-providing interface.
    *   Ensure IP forwarding is enabled: `cat /proc/sys/net/ipv4/ip_forward` (should be `1`).
    *   Verify the `iptables` NAT and FORWARD rules: `sudo iptables -t nat -L -v -n --line-numbers` and `sudo iptables -L FORWARD -v -n --line-numbers`.
    *   Check DNS settings on the client – it should be `192.168.73.1`.

This completes the setup for your Chernarus_Beacon Wi-Fi hotspot!
