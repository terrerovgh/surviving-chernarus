# Operación: The Perimeter - Raspberry Pi Network Security Setup

Welcome to "Operación: The Perimeter," a project to establish a secure and monitored Wi-Fi hotspot environment using a Raspberry Pi 5. This setup includes a Wi-Fi access point, a suite of Dockerized services including a captive portal, DHCP server, Pi-hole for DNS, Squid proxy, and placeholders for future dashboard and logging services, all managed by a central `docker-compose.yml`.

This README provides a consolidated overview and deployment plan. Detailed setup guides for legacy components or specific configurations are available in their respective directories where applicable.

## Project Components and Thematic Names:

*   **Wi-Fi Hotspot (`Chernarus_Beacon`):** Provides wireless access. (`wlan0` interface, network typically `192.168.100.0/24` as per `dhcpd.conf`)
*   **Captive Portal (`Chernarus_Entrypoint`):** Guides users to install the necessary CA certificate for HTTPS inspection. (Docker container, Nginx, part of main compose setup)
*   **Squid Proxy (`Berezino_Checkpoint`):** Transparently proxies HTTP/HTTPS traffic for caching and potential filtering. (Docker container, part of main compose setup)
*   **Pi-hole (`StarySobor_RadioPost`):** DNS filtering and caching. (Docker container)
*   **DHCP Server (`dhcp_server`):** Provides IP addresses to clients on the hotspot. (Docker container using host network)
*   **Dashboard Placeholder:** Future location for monitoring. (Docker container)
*   **Logging Placeholder:** Future location for centralized logs. (Docker container)

## I. Generated Files and Key Directories

*   **`docker-compose.yml` (Root Directory):** The central Docker Compose file to manage all services.
**Hotspot Configuration (`Chernarus_Beacon`):**
*   `hotspot_config/hostapd.conf` (Wi-Fi AP configuration)
*   `hotspot_config/dhcp/dhcpd.conf` (Configuration for the `dhcp_server` container)
*   `scripts/setup_hotspot_nat.sh` (NAT and forwarding script for basic internet access)
*   `GUIDANCE_AND_EXPLANATIONS.md` (Detailed setup guide for the non-Dockerized hotspot component)

**Squid Proxy (`Berezino_Checkpoint`):**
*   `squid_Berezino_Checkpoint/squid.conf` (Squid proxy configuration, referenced by the root `docker-compose.yml`)
*   `squid_Berezino_Checkpoint/certs/.gitkeep` (Placeholder for SSL CA certificate - **user must add `myCA.pem` here**, referenced by `docker-compose.yml`)
*   `scripts/redirect_to_squid.sh` (iptables script to redirect traffic to Squid)
*   `squid_Berezino_Checkpoint/README_SQUID.md` (Detailed setup guide for the Squid proxy component)

**Captive Portal (`Chernarus_Entrypoint`):**
*   `captive_portal_Chernarus_Entrypoint/html/index.html` (Portal page for CA certificate download, referenced by `docker-compose.yml`)
*   `captive_portal_Chernarus_Entrypoint/html/.gitkeep` (Ensures `html` directory for `index.html` and CA cert - **user must add CA cert (e.g., `myCA.pem` or `.crt`) here for download**, referenced by `docker-compose.yml`)
*   `scripts/setup_captive_portal_redirect.sh` (iptables script to redirect users to portal)
*   `captive_portal_Chernarus_Entrypoint/README_PORTAL.md` (Detailed setup guide for the captive portal component)

**Pi-hole Data:**
*   Pi-hole data is stored in Docker named volumes (`pihole_etc_pihole`, `pihole_etc_dnsmasq_d`), managed by Docker.

**Repository Structure Overview:**
```
surviving-chernarus/
├── docker-compose.yml  # Central Docker Compose file
├── hotspot_config/
│   ├── hostapd.conf
│   └── dhcp/
│       └── dhcpd.conf
├── squid_Berezino_Checkpoint/
│   ├── certs/
│   │   └── .gitkeep
│   ├── README_SQUID.md
│   └── squid.conf
├── captive_portal_Chernarus_Entrypoint/
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

**Refer to component-specific READMEs or the `GUIDANCE_AND_EXPLANATIONS.md` for non-Docker setup details.**

**Phase 1: Prepare the Raspberry Pi OS & Network**
1.  **Static IP for `eth0` (Internet Interface):** Ensure your Raspberry Pi has a predictable static IP address on its main Ethernet interface (e.g., `eth0`).
2.  **Static IP for `wlan0` (Hotspot Interface):** Configure `wlan0` with a static IP (e.g., `192.168.100.1` if matching the `dhcpd.conf` gateway). This can be done via `/etc/dhcpcd.conf` or network management tools. The `GUIDANCE_AND_EXPLANATIONS.md` provides an example.
3.  **Install Required OS Packages:**
    ```bash
    sudo apt-get update
    sudo apt-get install -y hostapd iptables-persistent docker-ce docker-ce-cli containerd.io docker-compose-plugin
    ```
    (Note: For Docker, follow the official Docker installation guides for Raspberry Pi OS to get the latest versions, including `docker compose` v2 CLI plugin.)
4.  **Enable Docker Service:**
    ```bash
    sudo systemctl enable docker
    sudo systemctl start docker
    ```
5.  **USB Drive for Persistent Data (Recommended for Squid):**
    *   Ensure your USB drive is mounted (e.g., at `/mnt/usbdata`).
    *   The `docker-compose.yml` expects Squid cache and logs at `/mnt/usbdata/Berezino_Checkpoint/...`. Create these directories:
        ```bash
        sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/logs
        sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/cache
        # Adjust permissions if necessary for the user/group Squid runs as inside the container (often 'proxy' or UID 13).
        # Example: sudo chown -R 13:13 /mnt/usbdata/Berezino_Checkpoint
        # Or use chmod 777 initially for testing if permissions issues arise.
        ```

**Phase 2: Deploy Configurations from This Repository**
1.  **Clone Repository:** (Example path `/opt/surviving-chernarus`)
    ```bash
    # git clone https://github.com/yourusername/surviving-chernarus.git /opt/surviving-chernarus
    # cd /opt/surviving-chernarus  # IMPORTANT: Run docker compose commands from this root directory
    ```
2.  **Review and Customize (CRITICAL):**
    *   **`hotspot_config/hostapd.conf`:** Set a strong `wpa_passphrase`. Verify `country_code`.
    *   **`hotspot_config/dhcp/dhcpd.conf`:** Review interface in `dhcp_server` command in `docker-compose.yml` (default `wlan0`), IP ranges, DNS server (should be Pi-hole's IP).
    *   **SSL CA Certificate:**
        1.  Generate your CA certificate (e.g., `myCA.pem`). Refer to `squid_Berezino_Checkpoint/README_SQUID.md` for guidance.
        2.  Place this `myCA.pem` into `squid_Berezino_Checkpoint/certs/`. This path is referenced by the root `docker-compose.yml` for the Squid service.
        3.  Place a copy of the public certificate part (e.g., `myCA.pem` or `myCA.crt`) into `captive_portal_Chernarus_Entrypoint/html/`. This path is referenced by the root `docker-compose.yml` for the Nginx captive portal service.
        4.  Ensure the download link in `captive_portal_Chernarus_Entrypoint/html/index.html` correctly points to the certificate file you placed in its `html` directory.
    *   Review all scripts in `scripts/` directory to ensure interface names (`eth0`, `wlan0`) match your system.
    *   **Pi-hole Password:** Change the `WEBPASSWORD` in `docker-compose.yml` for the `pihole` service.

**Phase 3: Setup Hotspot (`Chernarus_Beacon`) - Non-Dockerized Part**
(See `GUIDANCE_AND_EXPLANATIONS.md` for details on `hostapd` if not using a Dockerized AP)
1.  **`hostapd` (Wireless Access Point):**
    ```bash
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    # Edit /etc/default/hostapd and set DAEMON_CONF="/etc/hostapd/hostapd.conf"
    sudo sed -i 's|^#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl start hostapd
    ```
2.  **DHCP (Handled by `dhcp_server` Docker container):**
    *   Configure `hotspot_config/dhcp/dhcpd.conf` according to your network needs (subnet, range, DNS servers).
    *   **IMPORTANT:** The DNS server provided to clients via DHCP should be the Pi-hole container's IP. Since `dhcp_server` is in `host` network mode, and Pi-hole is on a Docker bridge network (`frontend_network`), you might need to use the RPi's `wlan0` IP (e.g., `192.168.100.1`) as the DNS server in `dhcpd.conf`, provided Pi-hole's port 53 is mapped to the host. The `pihole` service in `docker-compose.yml` maps port `53:53/tcp` and `53:53/udp`.
    *   Ensure Pi-hole's own DHCP server (if it has one enabled by default in its settings) is **disabled** via its web admin interface (default port `8081` on the RPi's IP) to avoid conflicts with the dedicated `dhcp_server` container.
3.  **NAT & Forwarding (Basic Internet):**
    ```bash
    chmod +x scripts/setup_hotspot_nat.sh
    sudo ./scripts/setup_hotspot_nat.sh
    sudo netfilter-persistent save # Persist iptables rules
    ```

**Phase 4: Start All Dockerized Services (Captive Portal, Squid, Pi-hole, DHCP, etc.)**
1.  **Navigate to the root of the repository** (e.g., `/opt/surviving-chernarus`).
2.  **Start all services:**
    ```bash
    sudo docker compose up -d
    ```
3.  **Check logs for specific services (examples):**
    ```bash
    sudo docker compose logs -f chernarus_entrypoint
    sudo docker compose logs -f berezino_checkpoint
    sudo docker compose logs -f pihole
    sudo docker compose logs -f dhcp_server
    ```
4.  **To manage individual services:** `sudo docker compose [start|stop|restart|logs] [service_name]` (e.g., `pihole`, `dhcp_server`, `chernarus_entrypoint`, `berezino_checkpoint`).

**Phase 5: Setup `iptables` Redirections**
(These scripts should be run after Docker services, especially the proxy and portal, are confirmed running)
1.  **`iptables` Redirection to Portal (`Chernarus_Entrypoint`):**
    ```bash
    chmod +x scripts/setup_captive_portal_redirect.sh
    sudo ./scripts/setup_captive_portal_redirect.sh
    # This script attempts to insert rules at the top. Review rule order if issues.
    sudo netfilter-persistent save
    ```
2.  **`iptables` Redirection to Squid (`Berezino_Checkpoint`):**
    ```bash
    chmod +x scripts/redirect_to_squid.sh
    sudo ./scripts/redirect_to_squid.sh
    # This script adds rules after the portal's expected rules.
    sudo netfilter-persistent save
    ```

**Order of `iptables` Script Execution for NAT Table (`PREROUTING` chain for `wlan0`):**
The system relies on `iptables` rules being applied in a specific sequence. If you need to reset or reapply:
1.  `scripts/setup_hotspot_nat.sh` (Basic NAT/Forwarding)
2.  `scripts/setup_captive_portal_redirect.sh` (Redirects HTTP to portal)
3.  `scripts/redirect_to_squid.sh` (Redirects HTTP/HTTPS to Squid)
Always save rules with `sudo netfilter-persistent save` after changes.

**Phase 6: Client Device Configuration & Service Access**
1.  Connect a client device to the Wi-Fi SSID configured in `hostapd.conf`.
2.  The client should get an IP from the range specified in `hotspot_config/dhcp/dhcpd.conf`.
3.  Open a web browser and try to visit an **HTTP** website (e.g., `http://neverssl.com`). You should be redirected to the `Chernarus_Entrypoint` portal page (served by Nginx on host port `8080`).
4.  Download the CA certificate from the portal and install it.
5.  Test browsing **HTTPS** websites. Traffic should now be proxied by Squid (listening on host port `3128`), and browser warnings should be gone if the CA is trusted.
6.  **Access Pi-hole Admin:** `http://<RPi_wlan0_IP>:8081` (e.g., `http://192.168.100.1:8081`). Use the `WEBPASSWORD` set in `docker-compose.yml`.
7.  **Dashboard Placeholder Access:** `http://<RPi_IP>:8082` (e.g., `http://192.168.100.1:8082` or check `docker compose port dashboard_placeholder 80`).

## III. Assumptions and Clarifications

*   **`project_rules.md` and `user_rules.md`:** Not used; configuration based on standard practices.
*   **Pi-hole (`StarySobor_RadioPost`) Setup:** Pi-hole is now containerized as the `pihole` service. Access its admin interface via host port `8081`. Its own DHCP server functionality should be **disabled** if using the separate `dhcp_server` container.
*   **DHCP Service:** The `dhcp_server` container (using `networkboot/dhcpd`) handles DHCP allocations. It requires `network_mode: "host"`.
*   **Network Structure:**
    *   `frontend_network`: For client-facing services that don't need host networking (Captive Portal, Pi-hole DNS).
    *   `backend_network`: For internal/management services (Squid, Dashboard/Logging placeholders).
    *   `dhcp_server`: Uses `network_mode: host` to directly interact with the network interface for DHCP.
*   **Internet Connectivity:** Assumes `eth0` (or your primary internet interface) is configured for internet access and is the outbound interface for NAT.
*   **Firewall Base State:** Assumes a relatively permissive default `iptables` policy. The provided scripts add necessary rules.
*   **Security of CA Key:** The CA private key is highly sensitive. Protect it. The `.pem` file in `squid_Berezino_Checkpoint/certs/` should have restricted permissions on the host.
*   **Thematic Hostnames in DNS:** For Docker container hostnames (e.g., `berezino-checkpoint`, `pihole-dns-filter`) to be resolvable by clients or other containers (if on same Docker network), add them to Pi-hole's "Local DNS Records" via its web UI (e.g., `http://<RPi_wlan0_IP>:8081`). Point them to their respective container IPs on the Docker networks, or to the RPi's IP if ports are mapped.
*   **`iptables` vs. `nftables`:** This solution uses `iptables`. If your system uses `nftables` as the default backend, script adjustments will be needed.

This concludes the setup for "Operación: The Perimeter". Review all configurations carefully before and during deployment. Remember to test each phase incrementally. Good luck, survivor!
