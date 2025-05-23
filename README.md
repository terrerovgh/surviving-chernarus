# Operación: The Perimeter - Raspberry Pi Network Security Setup

Welcome to "Operación: The Perimeter," a project to establish a secure and monitored Wi-Fi hotspot environment using a Raspberry Pi 5. This setup includes a Wi-Fi access point, DHCP services integrated with Pi-hole, a transparent caching and filtering Squid proxy, and a captive portal for user guidance on CA certificate installation.

This README provides a consolidated overview and deployment plan. Detailed setup guides for each component are available in their respective directories.

**Important Documents:**
*   [Security Best Practices](./SECURITY.md) - Please review this for crucial security information.

## Project Components and Thematic Names:

*   **Wi-Fi Hotspot (`Chernarus_Beacon`):** Provides wireless access. (`wlan0` interface, network `192.168.73.0/24`)
*   **DHCP & DNS (via `StarySobor_RadioPost` - Pi-hole):** Manages IP assignments and DNS for the hotspot. (Pi-hole instance assumed to be running on the RPi at `192.168.73.1`)
*   **Squid Proxy (`Berezino_Checkpoint`):** Transparently proxies HTTP/HTTPS traffic for caching and potential filtering. (Docker container)
*   **Captive Portal (`Chernarus_Entrypoint`):** Guides users to install the necessary CA certificate for HTTPS inspection. (Docker container, Nginx)

## I. Generated Files and Key Directories

**Hotspot Configuration (`Chernarus_Beacon`):**
*   `hotspot_config/hostapd.conf` (Wi-Fi AP configuration)
*   `hotspot_config/pihole_custom_dnsmasq.conf` (DHCP configuration for Pi-hole/dnsmasq)
*   `scripts/setup_hotspot_nat.sh` (NAT and forwarding script for basic internet access)
*   `GUIDANCE_AND_EXPLANATIONS.md` (Detailed setup guide for the hotspot component)

**Squid Proxy (`Berezino_Checkpoint`):**
*   `squid_Berezino_Checkpoint/docker-compose.yml` (Docker Compose for Squid)
*   `squid_Berezino_Checkpoint/squid.conf` (Squid proxy configuration)
*   `squid_Berezino_Checkpoint/certs/.gitkeep` (Placeholder for SSL CA certificate - **user must add `myCA.pem` here**)
*   `scripts/redirect_to_squid.sh` (iptables script to redirect traffic to Squid)
*   `squid_Berezino_Checkpoint/README_SQUID.md` (Detailed setup guide for the Squid proxy component)

**Captive Portal (`Chernarus_Entrypoint`):**
*   `captive_portal_Chernarus_Entrypoint/docker-compose.yml` (Docker Compose for Nginx portal)
*   `captive_portal_Chernarus_Entrypoint/html/index.html` (Portal page for CA certificate download)
*   `captive_portal_Chernarus_Entrypoint/html/.gitkeep` (Ensures `html` directory for `index.html` and CA cert - **user must add CA cert (e.g., `myCA.pem` or `.crt`) here for download**)
*   `scripts/setup_captive_portal_redirect.sh` (iptables script to redirect users to portal)
*   `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` (Detailed setup guide for the captive portal component)

**Repository Structure Overview:**
```
surviving-chernarus/
├── hotspot_config/
│   ├── hostapd.conf
│   └── pihole_custom_dnsmasq.conf
├── squid_Berezino_Checkpoint/
│   ├── certs/
│   │   └── .gitkeep
│   ├── docker-compose.yml
│   ├── README_SQUID.md
│   └── squid.conf
├── captive_portal_Chernarus_Entrypoint/
│   ├── docker-compose.yml
│   ├── html/
│   │   ├── .gitkeep
│   │   └── index.html
│   └── README_PORTAL.md
├── scripts/
│   ├── redirect_to_squid.sh
│   ├── setup_captive_portal_redirect.sh
│   └── setup_hotspot_nat.sh
├── GUIDANCE_AND_EXPLANATIONS.md
└── README.md  # This file
```

## II. Deployment and Execution Summary

**Refer to the detailed README files within each component's directory for in-depth explanations and troubleshooting.**

### Important: Initial Security Setup
**Failure to set these credentials will result in an insecure Pi-hole setup (default or no password) and a Wi-Fi network using a known placeholder password.**

**1. Configure Pi-hole Admin Password**
The default Pi-hole web admin password is no longer hardcoded in the main `docker-compose.yml` file. You must set it using an environment variable.

*   Create a file named `.env` in the root directory of this project (the same directory where `docker-compose.yml` is located).
*   Add the following content to the `.env` file:
    ```env
    PIHOLE_WEBPASSWORD=your_very_strong_and_unique_password_here
    ```
*   **Crucially, replace `your_very_strong_and_unique_password_here` with a strong, unique password.**
*   `docker-compose` (version 1.27+ or `docker compose` v2) will automatically load this `.env` file when you run `docker-compose up` (or `docker compose up`) and set the `PIHOLE_WEBPASSWORD` environment variable for the `pihole` service.
*   This password is required to access the Pi-hole admin interface, typically found at `http://<RPi_IP_Address>:8081/admin/` (e.g., `http://192.168.73.1:8081/admin/`).

**2. Configure Wi-Fi Passphrase (WPA Key)**
The default Wi-Fi passphrase in `hotspot_config/hostapd.conf` has been changed to a placeholder. You **must** set your own password.

*   Manually edit the `hotspot_config/hostapd.conf` file.
*   Find the line:
    ```
    wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE
    ```
*   Replace `CHANGEME_SET_YOUR_WPA_PASSPHRASE` with your own strong and unique Wi-Fi password. For example:
    ```
    wpa_passphrase=mySecureWiFiPassword123!
    ```
*   It is critical to use a strong WPA2 passphrase (long, complex, and not easily guessable) to secure your Wi-Fi network.
*   The `hostapd` service, which runs directly on the Raspberry Pi OS, uses this configuration file. The new passphrase will take effect when `hostapd` is started or restarted. This typically happens upon system boot or when manually managing the service (e.g., `sudo systemctl restart hostapd`).

**Phase 1: Prepare the Raspberry Pi OS & Network**
1.  **Static IP for `eth0` (Internet Interface):** Ensure your Raspberry Pi has a predictable static IP address on its main Ethernet interface (e.g., `eth0`) if it doesn't already. This is good practice for a server.
2.  **Static IP for `wlan0` (Hotspot Interface):** Configure `wlan0` with the static IP `192.168.73.1` (netmask `255.255.255.0`). This can be done via `/etc/dhcpcd.conf` or network management tools. The `GUIDANCE_AND_EXPLANATIONS.md` provides an example.
3.  **Install Required OS Packages:**
    ```bash
    sudo apt-get update
    sudo apt-get install -y hostapd iptables-persistent docker.io docker-compose
    ```
    (Note: `docker.io` and `docker-compose` package names might vary. Use official Docker installation guides for Raspberry Pi OS if needed.)
4.  **Enable Docker Service:**
    ```bash
    sudo systemctl enable docker
    sudo systemctl start docker
    ```
5.  **USB Drive for Persistent Data (Recommended):**
    *   Ensure your USB drive is mounted (e.g., at `/mnt/usbdata`).
    *   Create subdirectories for Squid data:
        ```bash
        sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/logs
        sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/cache
        # Adjust permissions if necessary. Example for Squid user (proxy, UID 31):
        # sudo chown -R 31:31 /mnt/usbdata/Berezino_Checkpoint
        # Or use chmod 777 initially for testing if permissions issues arise.
        ```

**Phase 2: Deploy Configurations from This Repository**
1.  **Clone Repository:** (Example path `/opt/surviving-chernarus`)
    ```bash
    # git clone https://github.com/yourusername/surviving-chernarus.git /opt/surviving-chernarus
    # cd /opt/surviving-chernarus
    ```
2.  **Review and Customize (CRITICAL):**
    *   **`hotspot_config/hostapd.conf`:** Set a strong `wpa_passphrase`. Verify `country_code`.
    *   **SSL CA Certificate:**
        1.  Generate your CA certificate (e.g., `myCA.pem` containing both key and cert). Refer to `squid_Berezino_Checkpoint/README_SQUID.md` for guidance.
        2.  Place this `myCA.pem` into `squid_Berezino_Checkpoint/certs/`.
        3.  Place a copy of the public certificate part (e.g., `myCA.pem` or `myCA.crt`) into `captive_portal_Chernarus_Entrypoint/html/` for download by clients.
        4.  Ensure the download link in `captive_portal_Chernarus_Entrypoint/html/index.html` (e.g., `href="/myCA.pem"`) correctly points to the certificate file you placed in the `html` directory.
    *   Review all scripts in `scripts/` directory to ensure interface names (`eth0`, `wlan0`) match your system.

**Phase 3: Setup Hotspot (`Chernarus_Beacon`)**
(See `GUIDANCE_AND_EXPLANATIONS.md` for details)
1.  **`hostapd`:**
    ```bash
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    # Edit /etc/default/hostapd and set DAEMON_CONF="/etc/hostapd/hostapd.conf"
    sudo sed -i 's|^#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl start hostapd
    ```
2.  **DHCP (via Pi-hole/dnsmasq):**
    ```bash
    sudo cp hotspot_config/pihole_custom_dnsmasq.conf /etc/dnsmasq.d/02-chernarus-hotspot-dhcp.conf # Example name
    sudo pihole restartdns # or sudo systemctl restart pihole-FTL.service
    ```
    Verify in Pi-hole admin DHCP settings.
3.  **NAT & Forwarding (Basic Internet):**
    ```bash
    chmod +x scripts/setup_hotspot_nat.sh
    sudo ./scripts/setup_hotspot_nat.sh
    sudo netfilter-persistent save # Persist iptables rules
    ```

**Phase 4: Setup Captive Portal (`Chernarus_Entrypoint`)**
(See `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` for details)
1.  **Docker Service:** Navigate to `captive_portal_Chernarus_Entrypoint/`.
    ```bash
    sudo docker-compose up -d
    ```
    Check logs: `sudo docker-compose logs -f chernarus_entrypoint`
2.  **`iptables` Redirection to Portal:**
    ```bash
    chmod +x scripts/setup_captive_portal_redirect.sh
    sudo ./scripts/setup_captive_portal_redirect.sh
    # This script attempts to insert rules at the top. Review rule order if issues.
    sudo netfilter-persistent save
    ```

**Phase 5: Setup Squid Proxy (`Berezino_Checkpoint`)**
(See `squid_Berezino_Checkpoint/README_SQUID.md` for details)
1.  **Docker Service:** Navigate to `squid_Berezino_Checkpoint/`.
    ```bash
    sudo docker-compose up -d
    ```
    Check logs: `sudo docker-compose logs -f berezino_checkpoint`
2.  **`iptables` Redirection to Squid:**
    ```bash
    chmod +x scripts/redirect_to_squid.sh
    sudo ./scripts/redirect_to_squid.sh
    # This script adds rules after the portal's expected rules.
    sudo netfilter-persistent save
    ```

**Order of `iptables` Script Execution for NAT Table (`PREROUTING` chain for `wlan0`):**
The system relies on `iptables` rules being applied in a specific sequence. If you need to reset or reapply:
1.  `scripts/setup_hotspot_nat.sh` (Basic NAT/Forwarding - less specific, broader rules)
2.  `scripts/setup_captive_portal_redirect.sh` (Redirects HTTP to portal - more specific, should be early)
3.  `scripts/redirect_to_squid.sh` (Redirects HTTP/HTTPS to Squid - processes what's left or bypasses portal for HTTPS)
Always save rules with `sudo netfilter-persistent save` after changes.

**Phase 6: Client Device Configuration**
1.  Connect a client device to the `rpi` Wi-Fi SSID.
2.  The client should get an IP from the `192.168.73.10-200` range.
3.  Open a web browser and try to visit an **HTTP** website (e.g., `http://neverssl.com`). You should be redirected to the `Chernarus_Entrypoint` portal page.
4.  Download the CA certificate from the portal and install it on the client device following the instructions on the portal page.
5.  Test browsing **HTTPS** websites. Traffic should now be proxied by Squid, and browser warnings should be gone if the CA is trusted.

## III. Assumptions and Clarifications

*   **`project_rules.md` and `user_rules.md`:** These files were not accessible. Configurations are based on standard practices.
*   **Pi-hole (`StarySobor_RadioPost`) Setup:** Assumes Pi-hole is already installed, functional, and accessible at `192.168.73.1` for DNS by hotspot clients.
*   **Internet Connectivity:** Assumes `eth0` (or your primary internet interface) is configured for internet access.
*   **Firewall Base State:** Assumes a relatively permissive default `iptables` policy. The provided scripts add necessary rules for the project's functionality.
*   **Security of CA Key:** The CA private key is highly sensitive. Protect it. The `.pem` file in `squid_Berezino_Checkpoint/certs/` should have restricted permissions on the host.
*   **Thematic Hostnames in DNS:** For hostnames like `berezino-checkpoint` to be resolvable by clients, add them to Pi-hole's "Local DNS Records" pointing to `192.168.73.1`.
*   **`iptables` vs. `nftables`:** This solution uses `iptables`. If your system uses `nftables` as the default backend, script adjustments will be needed.

This concludes the setup for "Operación: The Perimeter". Review all component READMEs and configurations carefully before and during deployment. Remember to test each phase incrementally. Good luck, survivor!
