# Berezino_Checkpoint (Squid Proxy) Setup Guide

This guide provides instructions for setting up the `Berezino_Checkpoint` Squid proxy using Docker on your Raspberry Pi 5. This proxy is intended to transparently intercept HTTP and HTTPS traffic from clients connected to the `rpi` Wi-Fi hotspot (`192.168.73.0/24`).

## Generated Configuration Files:

1.  **`squid_Berezino_Checkpoint/docker-compose.yml`**: Docker Compose configuration to run Squid.
2.  **`squid_Berezino_Checkpoint/squid.conf`**: Custom configuration for Squid, enabling transparent proxying and SSL bumping.
3.  **`squid_Berezino_Checkpoint/certs/`**: Directory to store your SSL CA certificate (you must create this).
4.  **`scripts/redirect_to_squid.sh`**: Script to set up `iptables` rules for redirecting hotspot traffic to Squid.

## I. Prerequisites

*   Ensure Docker and Docker Compose are installed on your Raspberry Pi 5.
*   Ensure the Wi-Fi hotspot (`rpi` SSID on `wlan0`, network `192.168.73.0/24`) is operational as per the previous `Chernarus_Beacon` setup.
*   The NAT script (`scripts/setup_hotspot_nat.sh`) from the hotspot setup should already be in place and configured to allow general internet access for hotspot clients.
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
    sudo chmod -R 777 /mnt/usbdata/Berenizo_Checkpoint/logs
    ```

## II. Managing CA Certificate and Key for SSL Bumping

For Squid to intercept and inspect HTTPS traffic (`SSL Bumping`), you must generate and manage your own Certificate Authority (CA) certificate and private key. This CA is used by Squid to dynamically create certificates for the websites users visit. The `squid_Berezino_Checkpoint/certs/` directory is mapped to `/etc/squid/certs/` inside the Docker container.

### 1. CA Certificate and Key Generation

The current `squid.conf` is configured to use `myCA.pem` as the public certificate (`cert=`) and `myCA.key` as the private key (`key=`).

*   **Generate the CA private key and public certificate:**
    Use OpenSSL on your Raspberry Pi or another Linux machine. The following command generates a 4096-bit RSA key (`myCA.key`) and a self-signed certificate (`myCA.pem`) valid for 10 years.
    ```bash
    openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes \
      -out myCA.pem \
      -keyout myCA.key \
      -subj "/CN=BerezinoCheckpointCA/O=ChernarusNetwork/OU=ProxyServices"
    ```
    This creates:
    *   `myCA.key`: Your private key. **Protect this file!**
    *   `myCA.pem`: Your public CA certificate in PEM format. This is what Squid uses via the `cert=` directive.

*   **Create a DER version for client distribution (optional but recommended):**
    Some devices prefer the DER format for importing CA certificates.
    ```bash
    openssl x509 -in myCA.pem -outform DER -out myCA.der
    ```
    You will distribute either `myCA.pem` or `myCA.der` to clients.

*   **Place files in the `certs` directory:**
    Copy the generated `myCA.pem` and `myCA.key` files into the `squid_Berezino_Checkpoint/certs/` directory.
    ```bash
    # Assuming you are in the directory where you generated the files
    cp myCA.pem myCA.key path/to/your/cloned/repository/squid_Berezino_Checkpoint/certs/
    ```
    The `squid.conf` provided is already set up to look for these filenames:
    ```
    http_port 3129 transparent ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/certs/myCA.pem key=/etc/squid/certs/myCA.key
    ```

### 2. Security of Certificate and Key

*   **Protect Your Private Key:** The private key (`myCA.key`) is extremely sensitive. Anyone with access to it can impersonate any website to your proxy users. **Guard it carefully.**
*   **File Permissions:** Restrict permissions on the host system for the `certs` directory and its contents.
    Navigate to your repository root:
    ```bash
    chmod 700 ./squid_Berezino_Checkpoint/certs
    chmod 600 ./squid_Berezino_Checkpoint/certs/myCA.key
    chmod 644 ./squid_Berezino_Checkpoint/certs/myCA.pem
    # If you created myCA.der, its permissions can also be 644
    chmod 644 ./squid_Berezino_Checkpoint/certs/myCA.der
    ```
*   **Version Control:** **DO NOT COMMIT `myCA.key` or `myCA.pem` (or `.der`) TO GIT.** The `.gitignore` file in the repository should already be configured to ignore these files, but it's good practice to ensure they are not accidentally staged or committed. The `certs` directory contains a `.gitkeep` file to ensure the directory structure is present in the repository without including the sensitive files.

### 3. Certificate Rotation Policy

Regularly rotating your CA certificate is crucial for security. A compromised key or a key nearing its expiry date poses a risk. Aim to rotate annually or biennially.

*   **Manual Rotation Steps:**
    1.  **Generate a new key and certificate pair:**
        Use the OpenSSL commands from section II.1, but use new filenames, e.g., `myCA_new.key` and `myCA_new.pem`.
        ```bash
        # Example:
        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes \
          -out myCA_new.pem \
          -keyout myCA_new.key \
          -subj "/CN=BerezinoCheckpointCA-v2/O=ChernarusNetwork/OU=ProxyServices" # Consider updating CN
        ```
    2.  **Place new files in the `certs` directory:**
        Copy `myCA_new.key` and `myCA_new.pem` into `./squid_Berezino_Checkpoint/certs/`.
    3.  **Update Squid Configuration (Option A - Simpler):**
        *   Securely back up your old `myCA.key` and `myCA.pem`.
        *   Rename `myCA_new.key` to `myCA.key` and `myCA_new.pem` to `myCA.pem` within the `./squid_Berezino_Checkpoint/certs/` directory.
        ```bash
        # In ./squid_Berezino_Checkpoint/certs/
        mv myCA.key myCA_old.key
        mv myCA.pem myCA_old.pem
        mv myCA_new.key myCA.key
        mv myCA_new.pem myCA.pem
        ```
    4.  **Update Squid Configuration (Option B - If using different filenames in squid.conf):**
        Alternatively, if you prefer to keep versioned filenames, edit `squid_Berezino_Checkpoint/squid.conf` and update the `cert=` and `key=` parameters to point to the new files (e.g., `cert=/etc/squid/certs/myCA_new.pem key=/etc/squid/certs/myCA_new.key`).
    5.  **Restart Squid Container:**
        ```bash
        docker-compose restart Berezino_Checkpoint 
        # Or: docker-compose down && docker-compose up -d
        ```
    6.  **Distribute the New Public CA:**
        The new public certificate (`myCA_new.pem` or the new `myCA.pem`, or its `.der` equivalent) must be distributed and installed on all client devices. Users will see certificate errors until this is done.
    7.  **Securely Delete Old Private Key:**
        Once you've confirmed the new certificate and key are working correctly and clients have been updated, securely delete the old private key (e.g., `myCA_old.key`).
        *   Using `shred` (if available):
            ```bash
            shred -u ./squid_Berezino_Checkpoint/certs/myCA_old.key
            ```
        *   If `shred` is not available, overwrite it multiple times manually before deleting (less secure but better than a simple `rm`):
            ```bash
            # Example: find actual size and overwrite (replace 1234 with actual size)
            # dd if=/dev/urandom of=./squid_Berezino_Checkpoint/certs/myCA_old.key bs=1 count=1234 conv=notrunc
            # rm ./squid_Berezino_Checkpoint/certs/myCA_old.key
            ```
    8.  **Document Rotation:** Note the date of this rotation and schedule the next one.

*   **Automated Rotation:** Automating certificate rotation is an advanced topic, potentially involving tools like `certbot` (if you were using a publicly signed CA, which is not the case here) or custom scripting. For this setup, manual rotation is assumed.

### 4. Client Configuration (Trusting the CA)

Each client device (laptops, phones) connecting to the `rpi` hotspot **MUST** install and trust your public CA certificate (`myCA.pem` or `myCA.der`) in their system or browser trust store.
*   Without this, clients will experience certificate errors for every HTTPS site, as their browser will not recognize the authority signing the dynamically generated certificates from Squid.
*   The `Chernarus_Entrypoint` captive portal (to be set up later) should provide instructions and a download link for the CA certificate.

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

## V. `iptables` Traffic Redirection

To transparently redirect traffic from hotspot clients to the Squid proxy running in Docker, you need to apply `iptables` rules on the Raspberry Pi host.

1.  **Locate the Script:**
    The script `scripts/redirect_to_squid.sh` (from the main `scripts` directory in your cloned repository) is designed for this.

2.  **Make it Executable:**
    ```bash
    chmod +x path/to/your/cloned/repository/scripts/redirect_to_squid.sh
    ```

3.  **Run the Script:**
    Execute it with `sudo` privileges:
    ```bash
    sudo path/to/your/cloned/repository/scripts/redirect_to_squid.sh
    ```
    This script adds rules to the `nat` table's `PREROUTING` chain to redirect HTTP (port 80) and HTTPS (port 443) traffic from `wlan0` clients to Squid's respective ports (3128 and 3129) on the host machine.

4.  **Docker Networking and `127.0.0.1`:**
    The `iptables` rules redirect traffic to `127.0.0.1` (localhost) on the Raspberry Pi. Docker, through its port mappings defined in `docker-compose.yml` (e.g., `ports: - "3128:3128"`), makes the Squid container's ports accessible on the host's `127.0.0.1` interface. This is a standard method for redirecting host traffic to a Docker container.
    The script also includes rules to allow traffic *to* the Pi-hole/RPi itself on `wlan0` (DNS, DHCP, captive portal) to bypass this redirection.

5.  **Persistence:**
    The `iptables` rules are volatile and will be lost on reboot.
    *   If you installed `iptables-persistent` during the hotspot setup, save the current rules:
        ```bash
        sudo netfilter-persistent save
        ```
    *   If you modify rules or run other `iptables` scripts, remember to re-save.

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
Remember that `iptables` rules will remain until reboot or manually flushed/removed. If you stop Squid, you might want to remove or disable the redirection rules to restore direct internet access for hotspot clients.

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
    *   `iptables` redirection rules are incorrect or not applied.
    *   Squid is not running or not accessible.
    *   Outbound internet connectivity for Squid itself is blocked (check Raspberry Pi's main FORWARD rules and NAT setup from `setup_hotspot_nat.sh`).
    *   DNS resolution is failing for Squid (ensure `dns_nameservers 192.168.73.1` in `squid.conf` is correct and Pi-hole is working).
*   **Traffic Not Being Logged by Squid:**
    *   `iptables` rules are not correctly redirecting traffic.
    *   `acl localnet` in `squid.conf` does not match your hotspot network.
*   **Performance Issues:**
    *   Transparent proxying, especially SSL bumping, adds overhead. The Raspberry Pi 5 should handle a small number of clients, but monitor CPU/memory usage.
    *   Adjust `cache_mem` and `cache_dir` size in `squid.conf` as needed.

This completes the setup for the `Berezino_Checkpoint` Squid proxy.
