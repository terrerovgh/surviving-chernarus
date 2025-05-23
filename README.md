# Operación: The Perimeter - Raspberry Pi Network Security Setup

Welcome to "Operación: The Perimeter," a project to establish a secure and monitored Wi-Fi hotspot environment using a Raspberry Pi 5. This setup includes a Wi-Fi access point, a dedicated Docker-based DHCP server, Pi-hole for DNS filtering, a transparent caching and filtering Squid proxy, and a captive portal for user guidance on CA certificate installation.

This README provides a consolidated overview and deployment plan. Detailed setup guides for each component are available in their respective directories and the project wiki.

**Important Documents:**
*   [Security Best Practices](./SECURITY.md) - Please review this for crucial security information.

## Project Components and Thematic Names:

*   **Wi-Fi Hotspot (`Chernarus_Beacon`):** Provides wireless access via `hostapd` (`wlan0` interface, network `192.168.73.0/24`).
*   **DHCP Server (`Hotspot_DHCP_Server`):** A dedicated Docker container (`networkboot/dhcpd`) manages IP assignments for the hotspot.
*   **DNS Filter (`Pihole_DNS_Filter` - Pi-hole):** Pi-hole, running in a Docker container, provides DNS resolution and ad-blocking for hotspot clients. (Pi-hole instance accessible at `192.168.73.1`).
*   **Squid Proxy (`Berezino_Checkpoint`):** Transparently proxies HTTP/HTTPS traffic for caching and SSL inspection. (Docker container)
*   **Captive Portal (`Chernarus_Entrypoint`):** Guides users to install the necessary CA certificate for HTTPS inspection. (Docker container, Nginx)

## I. Generated Files and Key Directories

**Hotspot Configuration (`Chernarus_Beacon`):**
*   `hotspot_config/hostapd.conf` (Wi-Fi AP configuration, managed by `hostapd` service on the host).
*   `hotspot_config/dhcp/dhcpd.conf` (Configuration for the `Hotspot_DHCP_Server` Docker container).
*   `scripts/setup_hotspot_nat.sh` (NAT and forwarding script for basic internet access).
*   `GUIDANCE_AND_EXPLANATIONS.md` (Detailed setup guide for the hotspot component, OS-level networking, and `hostapd`).

**Dockerized Services (Managed via main `docker-compose.yml` in project root):**
*   **Pi-hole (`Pihole_DNS_Filter`):** DNS server. Configuration primarily through its web UI and environment variables in `docker-compose.yml`.
*   **DHCP Server (`Hotspot_DHCP_Server`):** Uses `hotspot_config/dhcp/dhcpd.conf`.
*   **Squid Proxy (`Berezino_Checkpoint`):**
    *   `squid_Berezino_Checkpoint/squid.conf` (Squid proxy configuration, mounted into container).
    *   `squid_Berezino_Checkpoint/certs/`: Directory for SSL CA certificate (user must add `myCA.pem` and `myCA.key`).
*   `scripts/redirect_to_squid.sh` (iptables script to redirect traffic to Squid).
*   `squid_Berezino_Checkpoint/README_SQUID.md` (Detailed setup guide for the Squid proxy component).
*   **Captive Portal (`Chernarus_Entrypoint`):**
    *   `captive_portal_Chernarus_Entrypoint/html/index.html` (Portal page for CA certificate download, mounted into Nginx container).
    *   `captive_portal_Chernarus_Entrypoint/html/`: Directory for portal assets including CA cert for download.
*   `scripts/setup_captive_portal_redirect.sh` (iptables script to redirect users to portal).
*   `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` (Detailed setup guide for the captive portal component).

**Main Docker Compose File:**
*   `docker-compose.yml` (in project root): Defines and manages all Dockerized services (Pi-hole, DHCP, Squid, Nginx portal).

**Repository Structure Overview (Key Files):**
```
surviving-chernarus/
├── docker-compose.yml                # Main Docker Compose file for all services
├── hotspot_config/
│   ├── hostapd.conf
│   └── dhcp/
│       └── dhcpd.conf
├── squid_Berezino_Checkpoint/
│   ├── certs/                        # For myCA.pem, myCA.key
│   │   └── .gitkeep
│   ├── README_SQUID.md
│   └── squid.conf
├── captive_portal_Chernarus_Entrypoint/
│   ├── html/                         # For index.html, CA cert download
│   │   └── .gitkeep
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
    sudo pacman -Syu --needed hostapd iptables-nft docker docker-compose
    ```
    *   `hostapd`: For the Wi-Fi access point.
    *   `iptables-nft`: For firewall management (provides `iptables` command with nftables backend).
    *   `docker` & `docker-compose`: For running containerized services.
    (Ensure you follow Arch Linux specific instructions for installing these if not already present, as per the wiki `[[05-Instalacion-Dependencias-Proyecto]]`.)
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
    *   **SSL CA Certificate (for Squid):**
        1.  Generate your CA certificate (`myCA.pem`) and private key (`myCA.key`). Refer to `squid_Berezino_Checkpoint/README_SQUID.md` for detailed guidance.
        2.  Place `myCA.pem` and `myCA.key` into `squid_Berezino_Checkpoint/certs/`.
        3.  Place a copy of the public certificate (e.g., `myCA.pem` or a `.crt` version of it) into `captive_portal_Chernarus_Entrypoint/html/` for client download.
        4.  Ensure the download link in `captive_portal_Chernarus_Entrypoint/html/index.html` (e.g., `href="/myCA.pem"`) correctly points to the certificate file.
    *   Review all scripts in `scripts/` directory to ensure interface names (e.g., `WLAN_IF="wlan0"`, `ETH_IF="eth0"`) match your system.
    *   Review `hotspot_config/dhcp/dhcpd.conf` to ensure IP ranges and DNS settings are correct.

**Phase 3: Setup Host-level Services (`hostapd` and Networking)**
(See `GUIDANCE_AND_EXPLANATIONS.md` and `[[06-Configurar-Hotspot]]` for details)
1.  **`hostapd` (Wi-Fi Access Point):**
    ```bash
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    # For Arch Linux, /etc/default/hostapd is not typically used.
    # Ensure hostapd service unit file points to /etc/hostapd/hostapd.conf or uses it by default.
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl start hostapd # Start hostapd after wlan0 has its static IP.
    ```
    *Ensure `wlan0` has its static IP `192.168.73.1/24` configured (e.g., via `systemd-networkd` as per wiki) before starting `hostapd`.*

2.  **NAT & Forwarding (Basic Internet):**
    ```bash
    chmod +x scripts/setup_hotspot_nat.sh
    sudo ./scripts/setup_hotspot_nat.sh
    # Persistence is handled in Phase 5
    ```

**Phase 4: Start Dockerized Services (Pi-hole, DHCP, Squid, Portal)**
(See component READMEs and relevant Wiki pages for details)
1.  **Navigate to Project Root:** Ensure you are in the root directory of the cloned repository (e.g., `/opt/surviving-chernarus`).
2.  **Start All Services:**
    ```bash
    sudo docker-compose up -d
    ```
    This command will:
    *   Pull necessary Docker images (Pi-hole, Squid, Nginx, `networkboot/dhcpd`).
    *   Create and start containers for `Pihole_DNS_Filter`, `Hotspot_DHCP_Server`, `Berezino_Checkpoint` (Squid), and `Chernarus_Entrypoint` (Nginx portal).
3.  **Verify Docker Services:**
    ```bash
    sudo docker ps -a
    # Check logs for any specific container if issues arise, e.g.:
    # sudo docker logs Pihole_DNS_Filter
    # sudo docker logs Hotspot_DHCP_Server
    ```

**Phase 5: Apply Traffic Redirection Rules & Persist `iptables`**
1.  **`iptables` Redirection to Portal & Squid:**
    Ensure you are in the project root directory.
    ```bash
    chmod +x scripts/setup_captive_portal_redirect.sh
    sudo ./scripts/setup_captive_portal_redirect.sh

    chmod +x scripts/redirect_to_squid.sh
    sudo ./scripts/redirect_to_squid.sh
2.  **Persist `iptables` Rules (Arch Linux):**
    ```bash
    sudo iptables-save > /etc/iptables/iptables.rules
    # If using IPv6 rules as well:
    # sudo ip6tables-save > /etc/iptables/ip6tables.rules
    # Ensure the iptables service is enabled to load rules on boot:
    sudo systemctl enable iptables.service
    # sudo systemctl enable ip6tables.service # If using IPv6
    ```

**Order of `iptables` Script Execution for NAT Table (`PREROUTING` chain for `wlan0`):**
It is critical that the `iptables` scripts are run in the correct order after any flush or on initial setup:
1.  `sudo ./scripts/setup_hotspot_nat.sh` (Establishes basic NAT, forwarding, and INPUT rules for essential services).
2.  `sudo ./scripts/setup_captive_portal_redirect.sh` (Inserts rules to redirect HTTP traffic to the captive portal).
3.  `sudo ./scripts/redirect_to_squid.sh` (Adds rules to redirect HTTP/HTTPS to Squid, ensuring portal and local services are bypassed correctly).
Always save the final ruleset using `iptables-save` as shown above.

**Phase 6: Client Device Configuration**
1.  Connect a client device to the `rpi` Wi-Fi SSID.
2.  The client should get an IP from the `192.168.73.10-200` range.
3.  Open a web browser and try to visit an **HTTP** website (e.g., `http://neverssl.com`). You should be redirected to the `Chernarus_Entrypoint` portal page.
4.  Download the CA certificate from the portal and install it on the client device following the instructions on the portal page.
5.  Test browsing **HTTPS** websites. Traffic should now be proxied by Squid, and browser warnings should be gone if the CA is trusted.

## III. Assumptions and Clarifications

*   **`project_rules.md` and `user_rules.md`:** These files were not accessible. Configurations are based on standard practices.
*   **Pi-hole (`Pihole_DNS_Filter`) and DHCP Server (`Hotspot_DHCP_Server`) Setup:** These are Dockerized services managed by the main `docker-compose.yml`. Pi-hole is assumed to be accessible at `192.168.73.1` for DNS. The DHCP server provides IPs on the `192.168.73.0/24` network.
*   **Internet Connectivity:** Assumes `eth0` (or your primary internet interface as defined in `scripts/setup_hotspot_nat.sh`) is configured for internet access.
*   **Firewall Base State:** Assumes a relatively permissive default `iptables` policy on the host. The provided scripts add necessary rules.
*   **Security of CA Key:** The Squid CA private key (`myCA.key`) is highly sensitive. Protect it as per `squid_Berezino_Checkpoint/README_SQUID.md`.
*   **Thematic Hostnames in DNS:** For hostnames like `berezino-checkpoint` or `chernarus-entrypoint` to be resolvable by clients, add them to Pi-hole's "Local DNS Records" pointing to `192.168.73.1`.
*   **`iptables` Backend:** This solution uses `iptables` commands. On Arch Linux, `iptables-nft` provides these commands using the `nftables` kernel backend, which is the modern approach.

This concludes the setup for "Chernarus Beacon" (Operación: The Perimeter). Review all component READMEs, Wiki pages, and configurations carefully before and during deployment. Remember to test each phase incrementally. Good luck, survivor!
