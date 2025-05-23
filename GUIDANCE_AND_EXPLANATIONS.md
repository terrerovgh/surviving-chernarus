# Wi-Fi Hotspot (Chernarus_Beacon) Setup Guide for Raspberry Pi 5

This guide provides instructions for setting up a Wi-Fi hotspot named `rpi` (internally referred to as `Chernarus_Beacon` for thematic purposes) on your Raspberry Pi 5 using the generated configuration files. The hotspot will operate on the `192.168.73.0/24` network, with the Raspberry Pi itself at `192.168.73.1` on the `wlan0` interface.

## Generated Configuration Files:

1.  **`hotspot_config/hostapd.conf`**: Configuration for `hostapd`, the software that creates the wireless access point.
2.  **`hotspot_config/pihole_custom_dnsmasq.conf`**: DHCP configuration for `dnsmasq` (managed by Pi-hole) to assign IP addresses to devices connecting to the hotspot.
3.  **`hotspot_config/dnsmasq_custom/03-terrerov-domain.conf`**: Custom dnsmasq configuration for resolving `*.terrerov.com` locally.
4.  **`scripts/setup_hotspot_nat_nft.sh`**: A shell script using `nftables` to configure Network Address Translation (NAT) and IP forwarding, allowing hotspot clients to access the internet through the Raspberry Pi's other network connection (e.g., `eth0`).

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

**Prerequisite: Pi-hole Installation**

This guide assumes you have already installed Pi-hole on your Raspberry Pi host system. If not, install it first using the official command:
```bash
curl -sSL https://install.pi-hole.net | bash
```
Follow the on-screen prompts during the Pi-hole installation. When asked about the interface, you can select your primary Ethernet interface (e.g., `eth0`). The custom configurations below will enable Pi-hole to also serve DHCP/DNS for the `wlan0` hotspot.

**DHCP Choice Explanation:**

For thematic consistency with `StarySobor_RadioPost` (your Pi-hole instance) and to centralize DNS and IP management, these instructions integrate DHCP services for the hotspot directly into Pi-hole. Pi-hole uses `dnsmasq` internally, which is a lightweight DHCP and DNS caching server. By adding a custom configuration file to Pi-hole's `dnsmasq` setup, we can make Pi-hole responsible for assigning IP addresses to devices connecting to the `Chernarus_Beacon` hotspot (`wlan0`). This avoids running a separate DHCP server and ensures that hotspot clients can easily use Pi-hole for DNS.

**Deployment Steps for DHCP & Custom DNS:**

1.  **Copy the Custom DHCP `dnsmasq` Configuration:**
    This file (`pihole_custom_dnsmasq.conf`) configures DHCP for the hotspot.
    Place the `hotspot_config/pihole_custom_dnsmasq.conf` file into the `/etc/dnsmasq.d/` directory on your Raspberry Pi.
    ```bash
    sudo cp hotspot_config/pihole_custom_dnsmasq.conf /etc/dnsmasq.d/02-chernarus-hotspot-dhcp.conf
    ```
    (The `02-` prefix helps with ordering if you have multiple custom files).

2.  **Copy the Custom `*.terrerov.com` Domain Resolution Configuration:**
    This file (`03-terrerov-domain.conf`) makes any domain ending in `.terrerov.com` resolve to `192.168.73.1`.
    Place the `hotspot_config/dnsmasq_custom/03-terrerov-domain.conf` file into the `/etc/dnsmasq.d/` directory.
    ```bash
    sudo cp hotspot_config/dnsmasq_custom/03-terrerov-domain.conf /etc/dnsmasq.d/03-terrerov-domain.conf
    ```

3.  **Restart Pi-hole's FTLDNS Service:**
    This will make `dnsmasq` pick up the new configurations.
    ```bash
    sudo pihole restartdns
    # OR, if the above command is not found or you prefer systemctl:
    # sudo systemctl restart pihole-FTL.service
    ```

4.  **Pi-hole `setupVars.conf` Check (Important):**
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

**NAT and IP Forwarding with `nftables` (`scripts/setup_hotspot_nat_nft.sh`):**

This script enables the Raspberry Pi to act as a router, forwarding traffic from the Wi-Fi hotspot clients (`wlan0`) to your main internet connection (e.g., `eth0`), using `nftables`. **This script initializes the entire `nftables` ruleset, potentially flushing any pre-existing rules.** It's designed to be the first firewall script you run.

1.  **Review Interface Variables:**
    Open `scripts/setup_hotspot_nat_nft.sh` with a text editor.
    *   Verify `ETH_IF="eth0"`: This variable should match your Raspberry Pi's internet-connected interface (e.g., `eth0`, `usb0`).
    *   Verify `WLAN_IF="wlan0"`: This should match your hotspot interface.
    *   Verify `HOTSPOT_NET="192.168.73.0/24"`: This should match your hotspot network.
    **You must edit these variables in the script if your setup differs.**

2.  **Make the Script Executable:**
    Navigate to the directory where you cloned the repository.
    ```bash
    chmod +x scripts/setup_hotspot_nat_nft.sh
    ```

3.  **Run the Script:**
    Execute the script with superuser privileges:
    ```bash
    sudo ./scripts/setup_hotspot_nat_nft.sh
    ```
    This will enable IP forwarding and set up the necessary `nftables` rules. The script includes rules to allow DHCP and DNS traffic to the Pi itself on `wlan0`, which are needed for Pi-hole/dnsmasq to function for hotspot clients.

4.  **Firewall Rule Persistence (`nftables`):**
    The `nftables` rules applied by this script are temporary and will be lost on reboot unless saved.
    *   **Ensure `nftables` is installed and enabled:** The main `README.md` covers installing `nftables`. Enable the service if not already:
        ```bash
        sudo systemctl enable nftables.service
        ```
    *   **Saving Rules:** After running this script (and any other `nftables` scripts like those for captive portal or Squid redirection, in the correct order), and verifying everything works, save the complete ruleset:
        ```bash
        sudo nft list ruleset > /etc/nftables.conf
        ```
        This command overwrites the default `nftables.conf` file. If you have other `nftables` rules you wish to preserve, you'll need to merge them manually.
    *   The `nftables.service` will automatically load `/etc/nftables.conf` on boot.

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
    *   Ensure `pihole-FTL.service` (dnsmasq) is running and configured correctly for `wlan0` (as per Section II). Check `/var/log/pihole-FTL.log` or `/var/log/daemon.log` / `/var/log/syslog` for dnsmasq errors.
    *   Verify the `nftables` rules allow DHCP: Run `sudo nft list ruleset`. Look for rules in the `input` chain of the `firewall_table` (or similar, as defined in `setup_hotspot_nat_nft.sh`) that accept UDP traffic on port 67 for the `wlan0` interface (e.g., `iifname "wlan0" udp dport 67 accept`).
*   **No internet on client devices**:
    *   Double-check the `ETH_IF` and `WLAN_IF` variables in `scripts/setup_hotspot_nat_nft.sh` match your actual interfaces.
    *   Ensure IP forwarding is enabled: `cat /proc/sys/net/ipv4/ip_forward` (should be `1`). The `setup_hotspot_nat_nft.sh` script should enable this.
    *   Verify the `nftables` NAT and FORWARD rules:
        *   Run `sudo nft list ruleset`.
        *   Check the `postrouting` chain in the `nat_table` (or similar, as defined in `setup_hotspot_nat_nft.sh`) for a masquerade rule for your hotspot network (e.g., `ip saddr 192.168.73.0/24 oifname "eth0" masquerade`).
        *   Check the `forward` chain in the `firewall_table` (or similar) for rules allowing traffic from `wlan0` to `eth0` and established/related traffic back.
    *   Check DNS settings on the client – it should be `192.168.73.1`. Ensure Pi-hole is functioning and resolving external domains.

This completes the setup for your Chernarus_Beacon Wi-Fi hotspot!
