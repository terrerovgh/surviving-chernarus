# Chernarus_Entrypoint (Captive Portal) Setup Guide

This guide provides instructions for setting up the `Chernarus_Entrypoint` captive portal using Docker on your Raspberry Pi 5. The portal's primary purpose is to guide users connecting to the `rpi` Wi-Fi hotspot (`192.168.73.0/24`) to download and install the necessary CA certificate for the `Berezino_Checkpoint` Squid proxy.

## Generated Configuration Files:

1.  **`captive_portal_Chernarus_Entrypoint/docker-compose.yml`**: Docker Compose configuration to run Nginx for serving the portal page.
2.  **`captive_portal_Chernarus_Entrypoint/html/index.html`**: The static HTML page for the portal.
3.  **`captive_portal_Chernarus_Entrypoint/html/.gitkeep`**: Ensures the `html` directory is tracked.
4.  **`scripts/setup_captive_portal_redirect.sh`**: Script to set up `iptables` rules for redirecting new hotspot clients to the portal.

## I. Prerequisites

*   Docker and Docker Compose are installed on your Raspberry Pi 5.
*   The Wi-Fi hotspot (`rpi` SSID on `wlan0`, network `192.168.73.0/24`) is operational.
*   The `Berezino_Checkpoint` Squid proxy is set up (though not necessarily running yet for initial portal setup).
*   You have the CA certificate file (e.g., `myCA.pem` or `myCA.crt`) that you generated for the Squid proxy (`Berezino_Checkpoint`).

## II. Prepare Portal Content

1.  **Copy CA Certificate to Portal's HTML Directory:**
    Place the CA certificate file (e.g., `myCA.pem` or `myCA.crt` – the one clients need to install, usually the `.crt` or the `.pem` if it's just the public cert) into the `captive_portal_Chernarus_Entrypoint/html/` directory. This makes it downloadable via the Nginx server.
    ```bash
    # Example: If your CA certificate is myCA.pem from the Squid setup
    cp path/to/squid_Berezino_Checkpoint/certs/myCA.pem path/to/captive_portal_Chernarus_Entrypoint/html/myCA.pem
    # Or if you have a .crt version for distribution:
    # cp path/to/myCA.crt path/to/captive_portal_Chernarus_Entrypoint/html/myCA.crt
    ```

2.  **Update Download Link in `index.html` (If Necessary):**
    Open `captive_portal_Chernarus_Entrypoint/html/index.html`.
    The current download link is:
    `<a href="/myCA.pem" download="Chernarus_Root_CA.pem" class="button">Download Chernarus_Root_CA.pem</a>`
    *   If your CA certificate file is named differently (e.g., `myCA.crt`), change `/myCA.pem` to `/myCA.crt` (or whatever your filename is).
    *   The `download="Chernarus_Root_CA.pem"` attribute suggests a user-friendly name for the file when saved by the user; you can keep this or change it.

## III. Docker Compose Setup (Nginx Portal Server)

The `Chernarus_Entrypoint` Nginx service, which serves the captive portal, is defined and managed by the main `docker-compose.yml` file located at the **root directory of the project repository**, not by a separate `docker-compose.yml` within the `captive_portal_Chernarus_Entrypoint/` directory.

1.  **To Start the Portal Service (and other project services):**
    Navigate to the root directory of your cloned repository (e.g., `~/projects/surviving-chernarus/`).
    Then, run:
    ```bash
    sudo docker-compose up -d chernarus_entrypoint
    ```
    Or, to start all services defined in the main `docker-compose.yml` (recommended for initial setup):
    ```bash
    sudo docker-compose up -d
    ```
    The portal will be accessible on the Raspberry Pi's `wlan0` IP at port `8080` (e.g., `http://192.168.73.1:8080`, assuming `192.168.73.1` is your RPi's `wlan0` IP), as configured in the main `docker-compose.yml`.

2.  **Check Container Status:**
    ```bash
    docker ps
    docker logs Chernarus_Entrypoint
    ```
    Ensure Nginx is running without errors. You should be able to access `http://192.168.73.1:8080` (or your RPi's `wlan0` IP on port 8080) from a device on the RPi's network (or from the RPi itself).

## IV. `iptables` Traffic Redirection

The `scripts/setup_captive_portal_redirect.sh` script configures `iptables` to redirect new users on the hotspot to the captive portal page.

1.  **Review the Script:**
    Familiarize yourself with `scripts/setup_captive_portal_redirect.sh`. It's designed to redirect HTTP (port 80) traffic from `wlan0` clients to the portal at `192.168.73.1:8080`.

2.  **Make it Executable:**
    ```bash
    chmod +x path/to/your/cloned/repository/scripts/setup_captive_portal_redirect.sh
    ```

3.  **Run the Script:**
    Execute it with `sudo` privileges:
    ```bash
    sudo path/to/your/cloned/repository/scripts/setup_captive_portal_redirect.sh
    ```

**Redirection Strategy and `iptables` Rule Order:**

*   **Simplified Approach:** The script inserts an `iptables` rule at the *top* of the `PREROUTING` chain in the `nat` table. This rule redirects all HTTP (port 80) requests from hotspot clients (`wlan0`) to the portal at `http://192.168.73.1:8080`.
*   **How it Works:**
    1.  A new user connects to the `rpi` Wi-Fi.
    2.  Their first HTTP request (e.g., to `http://example.com`) is caught by this rule and redirected.
    3.  They see the `index.html` page, download, and install the CA certificate.
    4.  After CA installation, HTTPS sites should work via the Squid proxy.
*   **Limitation:** HTTP sites will *continue* to be redirected to the portal. This might be acceptable if most critical browsing is HTTPS.
*   **Order of Execution for `iptables` Scripts:** For the whole system to work as intended, scripts affecting `iptables` should be run in a specific order:
    1.  `scripts/setup_hotspot_nat.sh` (Basic NAT and forwarding for internet access)
    2.  `scripts/setup_captive_portal_redirect.sh` (This portal redirection script - for HTTP)
    3.  `scripts/redirect_to_squid.sh` (Redirects HTTP and HTTPS to Squid)
    The portal script attempts to insert its rule first, ensuring it's processed before Squid's HTTP redirection. This order ensures the captive portal rule (from `setup_captive_portal_redirect.sh`) redirects HTTP traffic first. Additionally, `redirect_to_squid.sh` now includes a specific `RETURN` rule to prevent traffic directly accessing the portal on port 8080 from being re-redirected to Squid, further ensuring correct routing.

*   **Alternative (No Automatic Redirection):** If you prefer not to redirect all HTTP traffic:
    *   Do not run `scripts/setup_captive_portal_redirect.sh`.
    *   Modify Nginx in the main `docker-compose.yml` for the `chernarus_entrypoint` service to listen directly on port 80 of `192.168.73.1` (e.g., `ports: - "192.168.73.1:80:80"`), assuming no other service on the Pi uses port 80 on that IP.
    *   Instruct users to manually visit a specific address like `http://192.168.73.1` or a friendly DNS name (e.g., `http://welcome.chernarus.local`) that you configure in Pi-hole to point to `192.168.73.1`.

4.  **Persistence:**
    The `iptables` rules are volatile. After confirming functionality:
    *   **For Debian/Ubuntu based systems (like Raspberry Pi OS):**
        ```bash
        sudo apt-get update && sudo apt-get install -y iptables-persistent
        sudo netfilter-persistent save
        ```
    *   **For Arch Linux based systems:**
        `iptables-nft` is commonly used, providing the `iptables` command interface with an `nftables` backend, and includes services for persistence.
        ```bash
        # For Arch Linux, iptables-nft provides the modern iptables interface
        # and includes services for persistence.
        sudo pacman -Syu iptables-nft
        sudo systemctl enable iptables.service # To save rules on shutdown/load on boot
        sudo systemctl enable ip6tables.service # If using IPv6 rules
        # Then save rules using:
        sudo iptables-save > /etc/iptables/iptables.rules
        sudo ip6tables-save > /etc/iptables/ip6tables.rules # If using IPv6
        ```
        **Note:** The exact package and commands for `iptables` persistence can vary slightly on Arch Linux depending on whether you are using the `nftables` backend (common) or legacy `iptables`, and which helper utilities you prefer (e.g., `systemd` services vs. older scripts). The `iptables-nft` with `systemd` services is a common modern approach. Always consult the [Arch Wiki for iptables](https://wiki.archlinux.org/title/Iptables) and [nftables](https://wiki.archlinux.org/title/Nftables) for the most current practices. For simplicity, this guide focuses on the `iptables-nft` approach.
    *   If you re-run any of the `iptables` setup scripts or manually change rules, remember to save them again using the appropriate method for your system.

## V. Testing

1.  Ensure `Chernarus_Entrypoint` (Nginx) and `Berezino_Checkpoint` (Squid) Docker containers are running.
    Ensure `iptables` rules from all relevant scripts (`scripts/setup_hotspot_nat.sh`, `scripts/setup_captive_portal_redirect.sh`, `scripts/redirect_to_squid.sh`) have been applied in the correct order (see Section IV).
3.  Connect a **new client device** to the `rpi` Wi-Fi hotspot (SSID `rpi`).
4.  Open a web browser on the client and attempt to visit an **HTTP** website (e.g., `http://neverssl.com` or `http://example.com`). You should be redirected to the `Chernarus_Entrypoint` portal page, which is served from `http://192.168.73.1:8080`.
5.  From the portal page, download the CA certificate file (e.g., `Chernarus_Root_CA.pem`).
6.  Install and trust the CA certificate on the client device as per the instructions on the portal page.
7.  Attempt to visit an **HTTPS** website (e.g., `https://google.com`). It should now load correctly, with the certificate being issued by your CA (e.g., "BerezinoCheckpointCA").
8.  Verify that HTTP sites still redirect to the portal (this is the behavior of the simplified redirection approach described in Section IV).

## VI. Stopping the Portal

The `Chernarus_Entrypoint` Nginx service is managed as part of the main `docker-compose.yml` at the root of the repository.
To stop the Nginx portal service (and other services defined in the main `docker-compose.yml`):
```bash
cd path/to/your/cloned/repository/ # Navigate to the root of the repository
docker-compose down
```
To stop only the portal service if you wish to keep other services running (though they are inter-dependent):
```bash
cd path/to/your/cloned/repository/
docker-compose stop chernarus_entrypoint
```
This does not remove the `iptables` redirection rules. If you want to disable portal redirection:
1.  Manually remove the specific `iptables` rule. You can list rules with `sudo iptables -t nat -L PREROUTING --line-numbers` and then delete by line number: `sudo iptables -t nat -D PREROUTING <line_number>`.
2.  Alternatively, flush all rules (with caution, as this removes all NAT rules) and re-apply only those needed (e.g., from `setup_hotspot_nat.sh` and `redirect_to_squid.sh` if Squid is still in use).
3.  Save the changed `iptables` rules using the persistence method appropriate for your OS (see Section IV.4).

This completes the setup guide for the `Chernarus_Entrypoint` captive portal.
