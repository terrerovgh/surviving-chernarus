# Security Best Practices for Chernarus Beacon

Maintaining the security of your Chernarus Beacon hotspot is crucial to protect both the device and its users. This document outlines key security considerations and practices.

## 1. Keep Software Up-to-Date

Regularly updating all software components is one of the most effective ways to protect against known vulnerabilities.

### 1.1. Operating System (Arch Linux)
Update your Raspberry Pi's operating system frequently. Arch Linux is a rolling release, so updates can be frequent.
```bash
sudo pacman -Syu
```
Reboot if necessary, especially after kernel updates.

### 1.2. Docker Engine
Docker itself should be updated with the system:
```bash
sudo pacman -Syu
```
Ensure you are running a recent version of Docker.

### 1.3. Docker Images (Services)
The services running in Docker containers (Pi-hole, Squid, Nginx) should also be kept up-to-date.

*   **List current images:** `docker images`
*   **Pull the latest version of an image:**
    ```bash
    docker pull pihole/pihole:latest
    docker pull ubuntu/squid
    docker pull nginx:alpine
    # Add other images if used, e.g., for dashboard
    ```
*   **Recreate containers:** After pulling new images, you need to stop, remove (optional, but cleaner), and recreate your containers to use the new versions. If you used `docker-compose.yml`:
    ```bash
    # Ensure your docker-compose.yml specifies ':latest' tags or specific new versions
    docker-compose pull # Pulls all images defined in docker-compose.yml
    docker-compose up -d --force-recreate # Recreates containers using the new images
    ```
    Review the release notes for each image if significant changes are expected.

### 1.4. Network Services (hostapd)
The core network service `hostapd` (for the Wi-Fi hotspot), which runs on the host OS, is typically updated via system package management:
```bash
sudo pacman -Syu
```
Pi-hole uses `dnsmasq` internally for its DNS functions, and this is updated when the Pi-hole Docker image is updated (see section 1.3). The DHCP server is also a Docker container (`Hotspot_DHCP_Server`) and is updated similarly by pulling a new image if available.

## 2. Monitor for Vulnerabilities (CVEs)

Stay informed about Common Vulnerabilities and Exposures (CVEs) related to the software you use:

*   **Arch Linux:** Subscribe to the [Arch Linux security mailing list](https://lists.archlinux.org/listinfo/arch-security) or monitor the [Arch Linux Security Advisories](https://security.archlinux.org/).
*   **Docker:** Check the [Docker official blog](https://www.docker.com/blog/) and [security advisories](https://docs.docker.com/engine/security/non-events/).
*   **Squid Proxy:** Visit the [official Squid website](http://www.squid-cache.org/Versions/Vulnerabilities.html) for security information.
*   **Pi-hole:** Check the [Pi-hole GitHub repository](https://github.com/pi-hole/pi-hole) and [blog](https://pi-hole.net/blog/).
*   **Nginx:** Refer to the [Nginx security advisories](http://nginx.org/en/security_advisories.html).
*   **General CVE Databases:**
    *   [MITRE CVE List](https://cve.mitre.org/)
    *   [NIST National Vulnerability Database (NVD)](https://nvd.nist.gov/)

Regularly search these resources for mentions of the software versions you are running.

## 3. Secure Credentials
Ensure all default credentials are changed and strong, unique passwords/passphrases are used. Refer to the main `README.md` for instructions on setting:
*   Pi-hole web admin password
*   Wi-Fi WPA passphrase

## 4. Firewall Configuration
Proper firewall rules are essential. Ensure your `iptables` rules (managed via `scripts/setup_hotspot_nat.sh`, `scripts/setup_captive_portal_redirect.sh`, and `scripts/redirect_to_squid.sh`) are correctly configured.
For persistence on Arch Linux:
1.  Ensure `iptables-nft` is installed: `sudo pacman -Syu --needed iptables-nft`.
2.  Save rules after all scripts have been run: `sudo iptables-save > /etc/iptables/iptables.rules`.
3.  Enable the service to load rules on boot: `sudo systemctl enable iptables.service`.
These rules should restrict access to services as much as possible. Refer to `[[09-Configurar-Redireccion-Trafico]]` for more details on the `iptables` setup.

## 5. CA Certificate Management (Squid)
If using Squid for SSL bumping, manage your CA certificate and private key securely. Refer to `squid_Berezino_Checkpoint/README_SQUID.md` for details on generation, permissions, and rotation.

## 6. Service Hardening

Beyond keeping software up-to-date, consider these hardening steps:

### 6.1. Restrict Access to Management Interfaces
Administrative interfaces provide powerful control and should be protected:

*   **Pi-hole Admin:** The Pi-hole web interface (defaulting to port `8081` on the Raspberry Pi, e.g., `http://192.168.73.1:8081/admin/`) should ideally only be accessible from trusted networks or specific IP addresses.
    *   The `docker-compose.yml` is configured to bind this service to the Raspberry Pi's `wlan0` IP address (`192.168.73.1` by default).
    *   If you need to access it from outside the hotspot network (e.g., from your main LAN, assuming `eth0` is connected to it), consider using SSH tunneling to the Raspberry Pi and accessing `localhost:8081` through the tunnel, rather than exposing the port broadly.
    *   Alternatively, configure firewall rules on the Raspberry Pi (`iptables`) to only allow access to this port from specific trusted source IPs on `eth0` or other interfaces.
*   **Future Dashboards/Interfaces:** Apply similar principles if you add other web-based management tools.

### 6.2. Review Container Capabilities and Privileges
The `docker-compose.yml` file uses `cap_add: [NET_ADMIN]` for `berezino_checkpoint` (Squid) and `pihole`, and `network_mode: "host"` for `dhcp_server`.
*   These settings grant elevated privileges or broader network access. They are used for specific functional reasons (transparent proxying, DHCP operation, potential Pi-hole advanced features).
*   Understand why these are needed. If you modify the setup or find that certain features requiring these privileges are not used, consider if they can be restricted further (e.g., removing `NET_ADMIN` if Pi-hole doesn't strictly need it for your use case). However, the current setup likely requires them for full functionality.

## 7. Log Review and Auditing

Regularly reviewing logs can help detect issues, unauthorized access attempts, or suspicious activity.

### 7.1. Docker Container Logs
Each service running in Docker generates logs. You can view them using:
```bash
docker logs <container_name_or_id>
# For example:
docker logs Pihole_DNS_Filter
docker logs Berezino_Checkpoint
docker logs Chernarus_Entrypoint
```
To follow logs in real-time:
```bash
docker logs -f <container_name_or_id>
```
Check these logs for errors, repeated failed access attempts, or unusual traffic patterns.

### 7.2. Squid Access Logs
Squid logs are configured in `squid_Berezino_Checkpoint/squid.conf` to be stored in `/var/log/squid/` within the container, which is mapped to `./squid_Berezino_Checkpoint/logs/` on the host (if using the default USB mount point, it would be `/mnt/usbdata/Berezino_Checkpoint/logs/`).
*   `access.log`: Records all client requests. This can be very verbose but is invaluable for troubleshooting or investigating activity.
*   `cache.log`: Records Squid's own operational messages.

### 7.3. System Logs (Raspberry Pi OS)
The Raspberry Pi's own system logs can provide information about the host system, network events, and hardware.
```bash
sudo journalctl -xe  # View systemd journal, -xe for errors and extended info
sudo journalctl -u sshd # View logs for a specific service like sshd
```

### 7.4. Future Enhancements: Centralized Logging
For more robust auditing, especially in a production environment, consider setting up a centralized logging system (e.g., syslog forwarding to a remote server, or an ELK stack - Elasticsearch, Logstash, Kibana). This is an advanced topic beyond the scope of this initial setup.

## 8. Disable Unnecessary Services (Host OS)

To reduce the attack surface of the Raspberry Pi itself, ensure that only essential services are running on the host operating system.

*   **List running services:**
    ```bash
    systemctl list-units --type=service --state=running
    ```
*   **List all enabled services (will start on boot):**
    ```bash
    systemctl list-unit-files --type=service --state=enabled
    ```
*   **Review the lists:** Identify any services that are not required for the hotspot's operation or your management of the Raspberry Pi.
*   **Disable and stop unnecessary services:**
    ```bash
    sudo systemctl disable --now <service_name>
    ```
    For example, if you don't use Bluetooth, you might consider disabling `bluetooth.service`. Be cautious and ensure you understand what a service does before disabling it.

---

*This document provides a starting point. Security is an ongoing process. Always research best practices for the specific software versions you are using.*
