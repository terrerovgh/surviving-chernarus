# Operación: The Perimeter - Raspberry Pi Network Security Setup

Welcome to "Operación: The Perimeter," a project to establish a secure and monitored Wi-Fi hotspot environment using a Raspberry Pi 5. This setup includes a Wi-Fi access point, DHCP services integrated with Pi-hole, a transparent caching and filtering Squid proxy, and a captive portal for user guidance on CA certificate installation.

This README provides a consolidated overview and deployment plan. Detailed setup guides for each component are available in their respective directories.

## Project Components and Thematic Names:

*   **Wi-Fi Hotspot (`Chernarus_Beacon`):** Provides wireless access. (`wlan0` interface, network `192.168.73.0/24`)
*   **DHCP & DNS (via `StarySobor_RadioPost` - Pi-hole):** Manages IP assignments and DNS for the hotspot. (Pi-hole instance assumed to be running on the RPi at `192.168.73.1`)
*   **Squid Proxy (`Berezino_Checkpoint`):** Transparently proxies HTTP/HTTPS traffic for caching and potential filtering. (Docker container)
*   **Captive Portal (`Chernarus_Entrypoint`):** Guides users to install the necessary CA certificate for HTTPS inspection. (Docker container, Nginx)

## I. Generated Files and Key Directories

**Hotspot Configuration (`Chernarus_Beacon`):**
*   `hotspot_config/hostapd.conf` (Wi-Fi AP configuration)
*   `hotspot_config/pihole_custom_dnsmasq.conf` (DHCP configuration for Pi-hole/dnsmasq)
*   `scripts/setup_hotspot_nat_nft.sh` (nftables script for NAT and forwarding)
*   `GUIDANCE_AND_EXPLANATIONS.md` (Detailed setup guide for the hotspot component)

**Squid Proxy (`Berezino_Checkpoint`):**
*   `squid_Berezino_Checkpoint/docker-compose.yml` (Docker Compose for Squid)
*   `squid_Berezino_Checkpoint/squid.conf` (Squid proxy configuration)
*   `squid_Berezino_Checkpoint/certs/.gitkeep` (Placeholder for SSL CA certificate - **user must add `myCA.pem` here**)
*   `scripts/redirect_to_squid_nft.sh` (nftables script to redirect traffic to Squid)
*   `squid_Berezino_Checkpoint/README_SQUID.md` (Detailed setup guide for the Squid proxy component)

**Captive Portal (`Chernarus_Entrypoint`):**
*   `captive_portal_Chernarus_Entrypoint/docker-compose.yml` (Docker Compose for Nginx portal)
*   `captive_portal_Chernarus_Entrypoint/html/index.html` (Portal page for CA certificate download)
*   `captive_portal_Chernarus_Entrypoint/html/.gitkeep` (Ensures `html` directory for `index.html` and CA cert - **user must add CA cert (e.g., `myCA.pem` or `.crt`) here for download**)
*   `scripts/setup_captive_portal_redirect_nft.sh` (nftables script to redirect users to portal)
*   `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` (Detailed setup guide for the captive portal component)

**Repository Structure Overview:**
```
surviving-chernarus/
├── hotspot_config/
│   ├── hostapd.conf
│   ├── pihole_custom_dnsmasq.conf
│   └── dnsmasq_custom/
│       └── 03-terrerov-domain.conf
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
│   ├── cloudflare_ddns.py
│   ├── redirect_to_squid_nft.sh
│   ├── setup_captive_portal_redirect_nft.sh
│   └── setup_hotspot_nat_nft.sh
├── .env.example
├── GUIDANCE_AND_EXPLANATIONS.md
└── README.md  # This file
```

## II. Centralized Configuration (.env file)

This project uses a `.env` file at its root to manage sensitive and environment-specific configurations. This file is NOT committed to the repository (and should be listed in your `.gitignore` file).

**Setup:**

1.  Copy the example configuration file to `.env`:
    ```bash
    cp .env.example .env
    ```
2.  **Edit `.env`** with your specific values.
3.  **IMPORTANT**: Add `.env` to your project's `.gitignore` file to prevent accidentally committing your secrets:
    ```bash
    echo '.env' >> .gitignore
    ```

**Variables to Configure in `.env`:**

*   `PIHOLE_WEBPASSWORD`: Sets the admin password for the Dockerized Pi-hole web interface.
*   `TZ`: Sets the timezone for the Dockerized Pi-hole container (e.g., `America/Chicago`).
*   `CLOUDFLARE_API_TOKEN`: Your API Token for Cloudflare, used by the DDNS script. (Permissions: Zone.DNS:Edit for the specified zone).
*   `CLOUDFLARE_ZONE_NAME`: The domain name (zone) you manage in Cloudflare (e.g., `terrerov.com`).
*   `CLOUDFLARE_RECORD_NAME`: The specific 'A' record to update with your RPi's public IP (e.g., `rpi.terrerov.com`).

**Reference Variables (Manual Configuration):**

The following variables are commented out in `.env.example` but can be uncommented and used in your private `.env` file to keep track of the values you manually configure in `hotspot_config/hostapd.conf`:

*   `# WIFI_SSID="YourHotspotSSID"`
*   `# WIFI_PASSWORD="YourStrongPassword"`
*   `# WIFI_COUNTRY_CODE="US"`

**How It's Used:**

*   **Docker Compose:** `docker-compose.yml` automatically loads variables from the `.env` file for use in service definitions.
*   **Scripts:** Some scripts (like `scripts/cloudflare_ddns.py`) are designed to read these variables from the environment. Ensure the `.env` file is sourced or variables are otherwise exported when running such scripts (e.g., in a cron job).

## III. Deployment and Execution Summary

**Refer to the detailed README files within each component's directory for in-depth explanations and troubleshooting.**

**Phase 1: Prepare the Raspberry Pi OS & Network**
1.  **Static IP for `eth0` (Internet Interface):** Ensure your Raspberry Pi has a predictable static IP address on its main Ethernet interface (e.g., `eth0`) if it doesn't already. This is good practice for a server.
2.  **Static IP for `wlan0` (Hotspot Interface):** Configure `wlan0` with the static IP `192.168.73.1` (netmask `255.255.255.0`). This can be done via `/etc/dhcpcd.conf` or network management tools. The `GUIDANCE_AND_EXPLANATIONS.md` provides an example.
3.  **Install Required OS Packages:**
    *   **Pi-hole (Host):** Install Pi-hole on the host system using its official script. This provides the base DNS and DHCP capabilities.
        ```bash
        curl -sSL https://install.pi-hole.net | bash
        ```
    *   **Other Essential Packages:**
        ```bash
        sudo apt-get update
        sudo apt-get install -y hostapd nftables curl jq python3 python3-pip docker.io docker-compose
        ```
        (Note: `jq` and `python3`/`python3-pip` are primarily for the Cloudflare DDNS script. `docker.io` and `docker-compose` package names might vary; use official Docker installation guides for Raspberry Pi OS if needed.)
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
    *   **`hotspot_config/hostapd.conf`:** Set a strong `wpa_passphrase`. Verify `country_code`. Refer to the `.env.example` file for tracking your chosen `WIFI_SSID`, `WIFI_PASSWORD`, and `WIFI_COUNTRY_CODE`, which you will need to manually set in this file.
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
    *   **Custom DNS for `.terrerov.com`:** This setup also includes a custom Pi-hole configuration to resolve `*.terrerov.com` (and its subdomains) to the Raspberry Pi's local IP (`192.168.73.1`). To enable this, copy `hotspot_config/dnsmasq_custom/03-terrerov-domain.conf` to `/etc/dnsmasq.d/` on your Pi-hole host and restart Pi-hole DNS (`sudo pihole restartdns`).
3.  **NAT & Forwarding (Basic Internet with nftables):**
    ```bash
    chmod +x scripts/setup_hotspot_nat_nft.sh
    sudo ./scripts/setup_hotspot_nat_nft.sh
    # Rules are applied by the script. See "nftables Rule Order and Persistence" below.
    ```

**Phase 4: Setup Captive Portal (`Chernarus_Entrypoint`)**
(See `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` for details)
1.  **Docker Service:** Navigate to `captive_portal_Chernarus_Entrypoint/`.
    ```bash
    sudo docker-compose up -d
    ```
    Check logs: `sudo docker-compose logs -f chernarus_entrypoint`
2.  **`nftables` Redirection to Portal:**
    ```bash
    chmod +x scripts/setup_captive_portal_redirect_nft.sh
    sudo ./scripts/setup_captive_portal_redirect_nft.sh
    # This script adds rules. See "nftables Rule Order and Persistence" below.
    ```

**Phase 5: Setup Squid Proxy (`Berezino_Checkpoint`)**
(See `squid_Berezino_Checkpoint/README_SQUID.md` for details)
1.  **Docker Service:** Navigate to `squid_Berezino_Checkpoint/`.
    ```bash
    sudo docker-compose up -d
    ```
    Check logs: `sudo docker-compose logs -f berezino_checkpoint`
2.  **`nftables` Redirection to Squid:**
    ```bash
    chmod +x scripts/redirect_to_squid_nft.sh
    sudo ./scripts/redirect_to_squid_nft.sh
    # This script adds rules. See "nftables Rule Order and Persistence" below.
    ```

**nftables Rule Order and Persistence:**

The `nftables` firewall rules are critical and must be applied in a specific order. The provided scripts are designed to manage this:

1.  **`scripts/setup_hotspot_nat_nft.sh`**: This script should be run **first**. It flushes all existing rules and establishes the base NAT and firewall rules for hotspot internet access.
2.  **`scripts/setup_captive_portal_redirect_nft.sh`**: This script should be run **second**. It adds rules to redirect unauthenticated clients to the captive portal. It assumes the base rules from the NAT script are in place.
3.  **`scripts/redirect_to_squid_nft.sh`**: This script should be run **third (typically after client authentication or if portal is bypassed)**. It adds rules to transparently redirect HTTP/HTTPS traffic to the Squid proxy, including bypasses for local RPi services.

**Persistence:**
The `nftables` rules applied by these scripts are temporary and will be lost on reboot unless saved. To make them permanent:
*   **After running all three scripts in the correct order and verifying functionality:**
    1.  Save the current (working) ruleset to the default `nftables` configuration file:
        ```bash
        sudo nft list ruleset > /etc/nftables.conf
        ```
        *(This command overwrites `/etc/nftables.conf`. Review existing content if any, or merge rules carefully if you have pre-existing `nftables` configurations.)*
    2.  Enable the `nftables` service to automatically load these rules at boot:
        ```bash
        sudo systemctl enable nftables.service
        sudo systemctl start nftables.service
        ```
*   You can check the status of the service with `sudo systemctl status nftables.service` and view loaded rules with `sudo nft list ruleset`.

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
*   **Firewall Base State:** Assumes a relatively permissive default `nftables` policy (or that the scripts will correctly flush and apply rules). The provided scripts are designed to set up the necessary rules.
*   **Security of CA Key:** The CA private key is highly sensitive. Protect it. The `.pem` file in `squid_Berezino_Checkpoint/certs/` should have restricted permissions on the host.
*   **Thematic Hostnames in DNS:** For hostnames like `berezino-checkpoint` to be resolvable by clients, add them to Pi-hole's "Local DNS Records" pointing to `192.168.73.1`, or use the `*.terrerov.com` feature.
*   **Firewall Backend:** This solution now uses `nftables`. The scripts are written for `nftables`.

## IV. Advanced Configuration & Automation

### Cloudflare Dynamic DNS (DDNS)

For automatically updating a Cloudflare DNS record with your Raspberry Pi's dynamic public IP, this project includes the `scripts/cloudflare_ddns.py` script. This is useful if your ISP assigns you a dynamic public IP address.

Detailed setup instructions, including API token generation and cron job setup, are available in the wiki:
*   [Configurar DDNS con Cloudflare](wiki/es/15-Configurar-DDNS-Cloudflare.md)

This concludes the setup for "Operación: The Perimeter". Review all component READMEs and configurations carefully before and during deployment. Remember to test each phase incrementally. Good luck, survivor!
