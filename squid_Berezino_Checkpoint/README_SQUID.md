# Berezino_Checkpoint (Squid Proxy) Setup Guide

This guide provides instructions for setting up the `Berezino_Checkpoint` Squid proxy using Docker on your Raspberry Pi 5. This proxy is intended to transparently intercept HTTP and HTTPS traffic from clients connected to the `rpi` Wi-Fi hotspot (`192.168.73.0/24`).

## Generated Configuration Files:

1.  **`squid_Berezino_Checkpoint/docker-compose.yml`**: Docker Compose configuration to run Squid.
2.  **`squid_Berezino_Checkpoint/squid.conf`**: Custom configuration for Squid, enabling transparent proxying and SSL bumping.
3.  **`squid_Berezino_Checkpoint/certs/`**: Directory to store your SSL CA certificate (you must create this).
4.  **`scripts/redirect_to_squid_nft.sh`**: Script to set up `nftables` rules for redirecting hotspot traffic to Squid.

## I. Prerequisites

*   Ensure Docker and Docker Compose are installed on your Raspberry Pi 5.
*   Ensure the Wi-Fi hotspot (`rpi` SSID on `wlan0`, network `192.168.73.0/24`) is operational as per the previous `Chernarus_Beacon` setup.
*   The NAT script (`scripts/setup_hotspot_nat_nft.sh`) from the hotspot setup should already be in place and configured to allow general internet access for hotspot clients.
*   Create the necessary directories on your Raspberry Pi for persistent Squid data, ensuring they have appropriate permissions for the user/group running Docker (or make them world-writable if unsure, though less secure for production):
    ```bash
    sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/cache
    sudo mkdir -p /mnt/usbdata/Berezino_Checkpoint/logs
    # Example permissions (adjust if your Docker user is different or for security):
    # sudo chown -R <your_user>:<your_group> /mnt/usbdata/Berezino_Checkpoint
    # Or, if Squid runs as 'proxy' user inside the container (common for ubuntu/squid image):
    # The ubuntu/squid image runs as user 'proxy' (UID 31).
    # You might need to set permissions for this UID or use a volume driver that handles it.
    # For simplicity, you can initially try with open permissions and refine later:
    sudo chmod -R 777 /mnt/usbdata/Berezino_Checkpoint/cache
    sudo chmod -R 777 /mnt/usbdata/Berezino_Checkpoint/logs
    ```

## II. SSL Bumping CA Certificate Generation

For Squid to intercept and inspect HTTPS traffic (`SSL Bumping`), you must generate your own Certificate Authority (CA) certificate and private key. This CA will be used by Squid to dynamically create certificates for the websites users visit.

1.  **Generate CA Certificate and Key:**
    Use a tool like OpenSSL. On your Raspberry Pi or another Linux machine, run:
    ```bash
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout myCA.key -out myCA.crt -subj "/CN=BerezinoCheckpointCA/O=ChernarusNetwork/OU=ProxyServices"
    ```
    This creates `myCA.key` (private key) and `myCA.crt` (certificate).

2.  **Combine into a PEM file:**
    Squid's `squid.conf` is configured to use a single `.pem` file. Concatenate the key and certificate:
    ```bash
    cat myCA.crt myCA.key > myCA.pem
    ```

3.  **Place `myCA.pem` in the Certs Directory:**
    Copy the generated `myCA.pem` file into the `squid_Berezino_Checkpoint/certs/` directory (which you cloned from the repository). This directory is mapped to `/etc/squid/certs/` inside the Docker container.
    ```bash
    # Assuming you are in the directory where you generated myCA.pem
    cp myCA.pem path/to/your/cloned/repository/squid_Berezino_Checkpoint/certs/
    ```

4.  **Client Trust (Crucial):**
    Each client device (laptops, phones) connecting to the `rpi` hotspot **MUST** install and trust your `myCA.crt` (the certificate part, not the key) in their system or browser trust store.
    *   Without this, clients will see severe certificate errors for every HTTPS site.
    *   The `Chernarus_Entrypoint` captive portal (to be set up later) will provide instructions and a download link for `myCA.crt` for users.

## III. Squid Configuration (`squid.conf`)

The provided `squid_Berezino_Checkpoint/squid.conf` is configured for:
*   Transparent HTTP on port 3128.
*   Transparent HTTPS (SSL Bumping) on port 3129, using the CA from `./certs/myCA.pem`.
*   Access control allowing only clients from the `192.168.73.0/24` network.
*   Caching and logging to the directories mapped in `docker-compose.yml`.
*   Using `192.168.73.1` (Pi-hole) for DNS resolution by Squid.

**Note on `sslcrtd_program` Path:**
The path to `security_file_certgen` (the program Squid uses to generate certificates for SSL Bumping) is set to `/usr/lib/squid/security_file_certgen` in `squid.conf`. This is common for the `ubuntu/squid` Docker image. If Squid fails to start or SSL bumping doesn't work, check the Squid container logs (`docker logs Berezino_Checkpoint`) for errors related to this program. The path might differ in rare cases or future image updates.

## IV. Docker Compose Setup

The `squid_Berezino_Checkpoint/docker-compose.yml` file defines the Squid service.

1.  **Review Volumes:** Ensure the volume paths for cache and logs (`/mnt/usbdata/Berezino_Checkpoint/...`) are correct and the directories exist with proper permissions on your Raspberry Pi (as per Step I).
2.  **Navigate to the Directory:**
    Open a terminal on your Raspberry Pi and change to the directory containing the `docker-compose.yml` file:
    ```bash
    cd path/to/your/cloned/repository/squid_Berezino_Checkpoint/
    ```
3.  **Start Squid Service:**
    ```bash
    docker-compose up -d
    ```
    This will pull the `ubuntu/squid` image (if not already present) and start the `Berezino_Checkpoint` container in detached mode.

4.  **Check Container Status:**
    ```bash
    docker ps
    docker logs Berezino_Checkpoint
    ```
    Look for any errors in the logs. If Squid starts correctly, it should indicate it's ready to accept connections on ports 3128 and 3129.

## V. `nftables` Traffic Redirection

To transparently redirect traffic from hotspot clients to the Squid proxy running in Docker, you need to apply `nftables` rules on the Raspberry Pi host.

1.  **Locate the Script:**
    The script `scripts/redirect_to_squid_nft.sh` (from the main `scripts` directory in your cloned repository) is designed for this.

2.  **Make it Executable:**
    ```bash
    chmod +x path/to/your/cloned/repository/scripts/redirect_to_squid_nft.sh
    ```

3.  **Run the Script:**
    Execute it with `sudo` privileges:
    ```bash
    sudo path/to/your/cloned/repository/scripts/redirect_to_squid_nft.sh
    ```
    This script adds rules to the `nat` table's `prerouting` chain (or a similarly named table/chain if you've customized `setup_hotspot_nat_nft.sh`) to redirect HTTP (port 80) and HTTPS (port 443) traffic from `wlan0` clients to Squid's respective ports (3128 and 3129) on the host machine (127.0.0.1).

4.  **Docker Networking and `127.0.0.1`:**
    The `nftables` rules redirect traffic to `127.0.0.1` (localhost) on the Raspberry Pi. Docker, through its port mappings defined in `docker-compose.yml` (e.g., `ports: - "3128:3128"`), makes the Squid container's ports accessible on the host's `127.0.0.1` interface. This is a standard method for redirecting host traffic to a Docker container.
    The script also includes rules to allow traffic *to* the Pi-hole/RPi itself on `wlan0` (DNS, DHCP, captive portal) to bypass this redirection. These are added as `return` rules in the `prerouting` chain before the main Squid DNAT rules.

5.  **Persistence (`nftables`):**
    The `nftables` rules are volatile and will be lost on reboot unless saved.
    *   Ensure `nftables` service is enabled: `sudo systemctl enable nftables.service`.
    *   After running all necessary `nftables` scripts (`setup_hotspot_nat_nft.sh`, `setup_captive_portal_redirect_nft.sh`, and this `redirect_to_squid_nft.sh`) in the correct order and verifying functionality, save the complete ruleset:
        ```bash
        sudo nft list ruleset > /etc/nftables.conf
        ```
    *   If you modify rules or re-run any `nftables` scripts, remember to save the complete, working ruleset again to `/etc/nftables.conf`.

## VI. Testing and Verification

1.  **Connect a Client:** Connect a device to the `rpi` Wi-Fi hotspot.
2.  **Install CA Certificate:** On this client device, install and trust the `myCA.crt` you generated.
3.  **Test HTTP:** Browse to an HTTP website (e.g., `http://example.com`). Check Squid's access log:
    ```bash
    sudo tail -f /mnt/usbdata/Berezino_Checkpoint/logs/access.log
    # Or via Docker:
    # docker logs -f Berezino_Checkpoint
    ```
    You should see log entries for the HTTP request.
4.  **Test HTTPS:** Browse to an HTTPS website (e.g., `https://google.com`).
    *   If the CA certificate is correctly installed and trusted on the client, the site should load without errors.
    *   Check Squid's logs. You should see CONNECT requests being "bumped."
    *   Inspect the website's certificate in your browser. It should be issued by "BerezinoCheckpointCA" (or whatever CN you used).
5.  **Check Pi-hole:** Ensure DNS queries from the client (and from Squid itself) are still going through Pi-hole.

## VII. Stopping Squid

To stop the Squid proxy:
```bash
cd path/to/your/cloned/repository/squid_Berezino_Checkpoint/
docker-compose down
```
Remember that `nftables` rules will remain until reboot or manually flushed/removed. If you stop Squid, you might want to remove or disable the redirection rules to restore direct internet access for hotspot clients. This can be done by:
1.  Identifying the Squid redirection rules (e.g., via `sudo nft list ruleset -a` to get handles).
2.  Deleting them using their handles (e.g., `sudo nft delete rule ip nat_table prerouting handle <handle>`).
3.  Or, by editing `/etc/nftables.conf` to remove the rules and then reloading with `sudo systemctl reload nftables.service`.
Always save the desired ruleset to `/etc/nftables.conf` afterwards.

## Troubleshooting:

*   **Squid Not Starting:** Check `docker logs Berezino_Checkpoint`. Common issues:
    *   Incorrect `squid.conf` syntax.
    *   `sslcrtd_program` path incorrect.
    *   Permissions issues with volume mounts (`/mnt/usbdata/...`).
    *   CA certificate (`myCA.pem`) missing or incorrectly formatted in `./certs/`.
*   **Clients Get Certificate Errors:**
    *   The `myCA.crt` is not installed or not trusted on the client device.
    *   The `myCA.pem` used by Squid is different from the `myCA.crt` distributed to clients.
    *   `ssl_bump` rules in `squid.conf` are misconfigured.
*   **No Internet on Clients:**
    *   `nftables` redirection rules are incorrect or not applied. Check with `sudo nft list ruleset`.
    *   Squid is not running or not accessible.
    *   Outbound internet connectivity for Squid itself is blocked (check Raspberry Pi's main `nftables` FORWARD rules and NAT setup from `setup_hotspot_nat_nft.sh`).
    *   DNS resolution is failing for Squid (ensure `dns_nameservers 192.168.73.1` in `squid.conf` is correct and Pi-hole is working).
*   **Traffic Not Being Logged by Squid:**
    *   `nftables` rules are not correctly redirecting traffic. Check with `sudo nft list ruleset`.
    *   `acl localnet` in `squid.conf` does not match your hotspot network.
*   **Performance Issues:**
    *   Transparent proxying, especially SSL bumping, adds overhead. The Raspberry Pi 5 should handle a small number of clients, but monitor CPU/memory usage.
    *   Adjust `cache_mem` and `cache_dir` size in `squid.conf` as needed.

This completes the setup for the `Berezino_Checkpoint` Squid proxy.
