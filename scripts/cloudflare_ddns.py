import requests
import os
# import logging # Actual logging can be added later if needed

# Configuration will be via environment variables
# CLOUDFLARE_API_TOKEN = os.getenv("CLOUDFLARE_API_TOKEN")
# ZONE_NAME = os.getenv("CLOUDFLARE_ZONE_NAME")
# RECORD_NAME = os.getenv("CLOUDFLARE_RECORD_NAME")

def get_public_ip():
    """
    Fetches the public IP address from a list of online services.
    Returns:
        str: The public IP address as a string, or None if fetching failed.
    """
    ip_services = ["https://api.ipify.org", "https://icanhazip.com", "https://ifconfig.me/ip"]
    for service_url in ip_services:
        try:
            response = requests.get(service_url, timeout=10) # Increased timeout slightly
            response.raise_for_status() # Raises HTTPError for bad responses (4XX or 5XX)
            return response.text.strip()
        except requests.RequestException as e:
            print(f"Warning: Failed to get IP from {service_url}: {e}")
    print("Error: Failed to obtain public IP from all services.")
    return None

def get_zone_id(zone_name, api_token):
    """
    Retrieves the Zone ID for a given zone name from Cloudflare.
    Args:
        zone_name (str): The name of the Cloudflare zone (e.g., "example.com").
        api_token (str): The Cloudflare API token.
    Returns:
        str: The Zone ID, or None if not found or an error occurred.
    """
    headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}
    url = f"https://api.cloudflare.com/client/v4/zones?name={zone_name}"
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data.get("result") and len(data["result"]) > 0:
            return data["result"][0]["id"]
        else:
            print(f"Error: Zone '{zone_name}' not found or API token lacks permissions.")
            return None
    except requests.RequestException as e:
        print(f"Error: Cloudflare API error (get_zone_id): {e} - {e.response.text if e.response is not None and hasattr(e.response, 'text') else 'No response text'}")
        return None

def get_dns_record(zone_id, record_name, api_token):
    """
    Retrieves a specific DNS 'A' record from Cloudflare.
    Args:
        zone_id (str): The Cloudflare Zone ID.
        record_name (str): The full DNS record name (e.g., "ddns.example.com").
        api_token (str): The Cloudflare API token.
    Returns:
        dict: The DNS record details as a dictionary, or None if not found or an error occurred.
    """
    headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type=A&name={record_name}"
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data.get("result") and len(data["result"]) > 0:
            return data["result"][0] # Returns the first 'A' record found with that name
        else:
            # This is not necessarily an error, the record might not exist yet.
            print(f"Info: DNS record '{record_name}' not found in zone ID '{zone_id}'.")
            return None
    except requests.RequestException as e:
        print(f"Error: Cloudflare API error (get_dns_record): {e} - {e.response.text if e.response is not None and hasattr(e.response, 'text') else 'No response text'}")
        return None

def update_dns_record(zone_id, record_id, record_name, new_ip, api_token):
    """
    Updates an existing DNS 'A' record in Cloudflare.
    Args:
        zone_id (str): The Cloudflare Zone ID.
        record_id (str): The ID of the DNS record to update.
        record_name (str): The full DNS record name.
        new_ip (str): The new IP address to set for the record.
        api_token (str): The Cloudflare API token.
    Returns:
        bool: True if the update was successful, False otherwise.
    """
    headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
    payload = {
        "type": "A",
        "name": record_name,
        "content": new_ip,
        "ttl": 120,      # Time to Live in seconds. 120 is 2 minutes. 1 means 'automatic'.
        "proxied": False # False for DNS-only. True to enable Cloudflare proxy/CDN.
    }
    try:
        response = requests.put(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        print(f"Successfully updated DNS record '{record_name}' to '{new_ip}'.")
        return True
    except requests.RequestException as e:
        print(f"Error: Cloudflare API error (update_dns_record): {e} - {e.response.text if e.response is not None and hasattr(e.response, 'text') else 'No response text'}")
        return False

# Note: A create_dns_record function would be similar to update_dns_record,
# but using POST to /zones/{zone_id}/dns_records and not needing a record_id.
# This script assumes the A record is pre-created in Cloudflare.

if __name__ == "__main__":
    print("Cloudflare DDNS Script starting...")

    # Retrieve configuration from environment variables
    CLOUDFLARE_API_TOKEN = os.getenv("CLOUDFLARE_API_TOKEN")
    ZONE_NAME = os.getenv("CLOUDFLARE_ZONE_NAME")           # e.g., "example.com"
    RECORD_NAME = os.getenv("CLOUDFLARE_RECORD_NAME")       # e.g., "ddns.example.com" or "example.com" for root

    if not all([CLOUDFLARE_API_TOKEN, ZONE_NAME, RECORD_NAME]):
        print("Error: Missing one or more required environment variables: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ZONE_NAME, CLOUDFLARE_RECORD_NAME")
        exit(1)

    # 1. Get current public IP
    public_ip = get_public_ip()
    if not public_ip:
        print("Exiting: Could not determine public IP.")
        exit(1)
    print(f"Current public IP: {public_ip}")

    # 2. Get Cloudflare Zone ID
    zone_id = get_zone_id(ZONE_NAME, CLOUDFLARE_API_TOKEN)
    if not zone_id:
        print(f"Exiting: Could not determine Zone ID for {ZONE_NAME}.")
        exit(1)
    print(f"Zone ID for '{ZONE_NAME}': {zone_id}")

    # 3. Get current DNS record from Cloudflare
    dns_record = get_dns_record(zone_id, RECORD_NAME, CLOUDFLARE_API_TOKEN)

    if dns_record:
        current_cf_ip = dns_record["content"]
        print(f"Current Cloudflare IP for '{RECORD_NAME}': {current_cf_ip}")
        if public_ip == current_cf_ip:
            print("IP addresses match. No update needed.")
        else:
            print(f"IP addresses differ ({public_ip} vs {current_cf_ip}). Updating Cloudflare DNS record...")
            update_dns_record(zone_id, dns_record["id"], RECORD_NAME, public_ip, CLOUDFLARE_API_TOKEN)
    else:
        print(f"Warning: DNS A record '{RECORD_NAME}' not found. Please create it manually in Cloudflare for initial setup.")
        # Optionally, could call a create_dns_record function here if implemented.
    print("Cloudflare DDNS Script finished.")
