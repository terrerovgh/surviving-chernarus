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

The `captive_portal_Chernarus_Entrypoint/docker-compose.yml` file defines the Nginx service.

1.  **Navigate to the Directory:**
    Open a terminal on your Raspberry Pi and change to the directory containing this `docker-compose.yml` file:
    ```bash
    cd path/to/your/cloned/repository/captive_portal_Chernarus_Entrypoint/
    ```
2.  **Start Nginx Service:**
    ```bash
    docker-compose up -d
    ```
    This will pull the `nginx:alpine` image and start the `Chernarus_Entrypoint` container. The portal will be accessible on the Raspberry Pi's IP at port 8080 (e.g., `http://192.168.73.1:8080`).

3.  **Check Container Status:**
    ```bash
    docker ps
    docker logs Chernarus_Entrypoint
    ```
    Ensure Nginx is running without errors. You should be able to access `http://<RPi_IP>:8080` (e.g., `http://192.168.73.1:8080`) from a device on the RPi's network (or from the RPi itself).

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
    The portal script attempts to insert its rule first, ensuring it's processed before Squid's HTTP redirection.

*   **Alternative (No Automatic Redirection):** If you prefer not to redirect all HTTP traffic:
    *   Do not run `scripts/setup_captive_portal_redirect.sh`.
    *   Modify Nginx in `captive_portal_Chernarus_Entrypoint/docker-compose.yml` to listen directly on port 80 (e.g., `ports: - "80:80"`), assuming no other service on the Pi uses port 80.
    *   Instruct users to manually visit a specific address like `http://192.168.73.1` or a friendly DNS name (e.g., `http://welcome.chernarus.local`) that you configure in Pi-hole to point to `192.168.73.1`.

4.  **Persistence:**
    The `iptables` rules are volatile. After confirming functionality:
    *   Install `iptables-persistent` if not already done: `sudo apt-get update && sudo apt-get install -y iptables-persistent`
    *   Save the rules: `sudo netfilter-persistent save`
    *   If you re-run any of the `iptables` setup scripts or manually change rules, remember to save them again.

## V. Testing

1.  Ensure `Chernarus_Entrypoint` (Nginx) and `Berezino_Checkpoint` (Squid) Docker containers are running.
2.  Ensure `iptables` rules from all relevant scripts (`setup_hotspot_nat.sh`, `setup_captive_portal_redirect.sh`, `redirect_to_squid.sh`) have been applied in the correct order.
3.  Connect a **new client device** to the `rpi` Wi-Fi hotspot.
4.  Open a web browser on the client and attempt to visit an **HTTP** website (e.g., `http://neverssl.com` or `http://example.com`). You should be redirected to the `Chernarus_Entrypoint` portal page (`http://192.168.73.1:8080`).
5.  From the portal page, download the `Chernarus_Root_CA.pem` (or `.crt`) file.
6.  Install and trust the CA certificate on the client device as per the instructions on the portal page.
7.  Attempt to visit an **HTTPS** website (e.g., `https://google.com`). It should now load correctly, with the certificate being issued by your "BerezinoCheckpointCA".
8.  Verify that HTTP sites still redirect to the portal (this is the behavior of the simplified redirection).

## VI. Stopping the Portal

To stop the Nginx portal service:
```bash
cd path/to/your/cloned/repository/captive_portal_Chernarus_Entrypoint/
docker-compose down
```
This does not remove the `iptables` redirection rules. If you want to disable portal redirection, you'll need to manually remove the specific `iptables` rule or flush the `PREROUTING` chain (carefully, if other rules exist) and re-apply only the Squid redirection.
Example to delete the portal rule (if it's the first one in PREROUTING nat):
`sudo iptables -t nat -D PREROUTING 1`
Then re-save with `sudo netfilter-persistent save`.

This completes the setup for the `Chernarus_Entrypoint` captive portal.
