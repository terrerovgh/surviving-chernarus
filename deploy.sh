#!/bin/bash

# --- Error Handling ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Cause a pipeline to return the exit status of the last command in the pipe that failed.
set -o pipefail

# --- Script Configuration ---
# NGINX_WEB_ROOT: The directory where Nginx serves files for this site.
# This path is standard for user-deployed sites on Arch Linux (under /srv/http/).
# IMPORTANT:
# 1. This directory will be created by the script if it doesn't exist.
# 2. The 'github-runner' user (or the user executing this script) needs sudo privileges
#    to create this directory, run rsync with delete, chown, chmod, and restart nginx.
NGINX_WEB_ROOT="/srv/http/surviving-chernarus"

# --- Input Parameter Validation ---
# Check if the path to the downloaded artifact is provided as the first argument.
if [ -z "$1" ]; then
  echo "Error: No artifact path provided."
  echo "Usage: $0 <path_to_artifact>"
  exit 1
fi

# Store the artifact path from the first argument.
ARTIFACT_PATH="$1"
echo "Artifact path: $ARTIFACT_PATH"

# --- Deployment Steps ---
echo "Starting deployment to Nginx web root: $NGINX_WEB_ROOT ..."

# 1. Create Nginx web root directory if it doesn't exist.
#    The -p flag ensures that parent directories are also created if needed,
#    and it doesn't error if the directory already exists.
echo "Ensuring Nginx web root directory exists: $NGINX_WEB_ROOT"
sudo mkdir -p "$NGINX_WEB_ROOT"

# 2. Clear existing content from Nginx web root and copy new site files.
#    Using rsync with --delete is an efficient way to synchronize the content.
#    The source path "$ARTIFACT_PATH/" (with a trailing slash) means "copy the contents
#    of ARTIFACT_PATH".
#    The destination path "$NGINX_WEB_ROOT/" ensures files are placed directly into it.
#    --delete will remove any files in $NGINX_WEB_ROOT that are not in $ARTIFACT_PATH.
echo "Clearing old content and copying new site files from $ARTIFACT_PATH to $NGINX_WEB_ROOT ..."
sudo rsync -a --delete "$ARTIFACT_PATH/" "$NGINX_WEB_ROOT/"

# 3. Set appropriate permissions for the web files.
#    This is crucial for security and for Nginx to be able to read the files.
#    On Arch Linux, Nginx typically runs as the 'http' user and group.
echo "Setting permissions for $NGINX_WEB_ROOT ..."
# Set ownership to http:http
sudo chown -R http:http "$NGINX_WEB_ROOT"
# Set directory permissions to 755 (rwxr-xr-x)
sudo find "$NGINX_WEB_ROOT" -type d -exec chmod 755 {} \;
# Set file permissions to 644 (rw-r--r--)
sudo find "$NGINX_WEB_ROOT" -type f -exec chmod 644 {} \;

# 4. Restart Nginx to apply changes.
#    This ensures that Nginx serves the new files.
echo "Restarting Nginx service ..."
sudo systemctl restart nginx

echo "-------------------------------------"
echo "Deployment completed successfully!"
echo "Site deployed to: $NGINX_WEB_ROOT"
echo "-------------------------------------"

exit 0
