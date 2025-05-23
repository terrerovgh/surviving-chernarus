## Centralized Configuration (.env file)

To manage sensitive information (like API keys and passwords) and environment-specific settings, this project utilizes a `.env` file located in the project root (`/opt/surviving-chernarus/.env`). This approach keeps your secrets out of version control and makes configuration more straightforward.

### Purpose

The primary purpose of using a `.env` file is to:
*   **Secure Sensitive Data:** Keep API tokens, passwords, and other private details separate from the main codebase.
*   **Simplify Configuration:** Provide a single place to define settings that might change between different deployment environments or user preferences.
*   **Avoid Hardcoding:** Prevent embedding secrets directly into scripts or configuration files.

### `.env.example` Template

A template file named `.env.example` is provided in the project root. You should copy this template to create your own `.env` file:

```bash
cp .env.example .env
```

After copying, edit the `.env` file with your specific values.

### `.gitignore` - Crucial Security Step

**It is absolutely crucial to prevent your actual `.env` file (which contains your secrets) from being committed to version control (Git).**

If you are using Git for this project, add `.env` to your `.gitignore` file immediately:

```bash
echo '.env' >> .gitignore
```

This ensures that your sensitive information remains local to your deployment.

### Variables to Configure

The following variables are present in `.env.example` and should be configured in your `.env` file:

*   **`PIHOLE_WEBPASSWORD`**:
    *   **Purpose:** Sets the administrator password for the Pi-hole Docker container's web interface.
    *   **Example:** `YourPiholeAdminPassword`

*   **`TZ`**:
    *   **Purpose:** Defines the timezone for the Pi-hole Docker container (e.g., logs, scheduled tasks).
    *   **Example:** `America/Chicago` (Find your timezone from standard lists, e.g., [Wikipedia TZ Database Time Zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))

*   **`CLOUDFLARE_API_TOKEN`**:
    *   **Purpose:** Your Cloudflare API token with permissions to edit DNS records for your zone. This is used by the DDNS script (`scripts/cloudflare_ddns.py`).
    *   **Example:** `YourCloudflareAPIToken` (See `wiki/es/15-Configurar-DDNS-Cloudflare.md` for instructions on obtaining this token)

*   **`CLOUDFLARE_ZONE_NAME`**:
    *   **Purpose:** The root domain name you manage in Cloudflare (e.g., `terrerov.com`). Used by the DDNS script.
    *   **Example:** `terrerov.com`

*   **`CLOUDFLARE_RECORD_NAME`**:
    *   **Purpose:** The specific DNS 'A' record you want the DDNS script to update (e.g., `rpi.terrerov.com`).
    *   **Example:** `rpi.terrerov.com`

*   **Reference Wi-Fi Variables (Commented Out):**
    *   `# WIFI_SSID="YourHotspotSSID"`
    *   `# WIFI_PASSWORD="YourStrongPassword"`
    *   `# WIFI_COUNTRY_CODE="US"`
    *   **Purpose:** These are provided as a **reference only**. The hotspot configuration in `hostapd.conf` requires direct editing by the user. However, you can uncomment and use these variables in your `.env` file to keep a personal record of the SSID, password, and country code you have configured in `hostapd.conf`. This project **does not** automatically use these specific `.env` variables to configure `hostapd`.

### How It's Used

*   **Docker Compose:** `docker-compose.yml` is configured to automatically read and load variables from the `.env` file in the project root when starting services (like Pi-hole).
*   **Shell Scripts:** Some scripts, particularly those run by cron jobs (like `scripts/cloudflare_ddns.py`), are designed to have the `.env` file sourced before execution. This loads the variables into the script's environment. Detailed instructions are provided in the documentation for each relevant script (e.g., the cron setup for `cloudflare_ddns.py`).

By centralizing these configurations, you create a more secure and manageable setup for your Surviving Chernarus hotspot project. Remember to always keep your `.env` file private.
