#!/bin/bash

exec > /var/log/custom_startup.log 2>&1
set -e  # Exit immediately on error
set -x  # Enable command tracing for debugging

echo "DEBUG: Custom On-start Script execution started at $(date)"

# Ensure /workspace/ exists
echo "DEBUG: Checking /workspace/ directory..."
mkdir -p /workspace/
chmod 777 /workspace/

# Set up Rclone configuration early
echo "DEBUG: Setting up Rclone configuration..."
mkdir -p /root/.config/rclone
if [ ! -f /root/.config/rclone/rclone.conf ]; then
    echo "DEBUG: Creating Rclone configuration file..."
    cat <<EOF > /root/.config/rclone/rclone.conf
[dropbox]
type = dropbox
token = {"access_token": "${DROPBOX_TOKEN}", "token_type": "bearer"}
EOF
else
    echo "DEBUG: Rclone configuration already exists."
fi

# Initialize environment in a subshell
echo "DEBUG: Initializing environment..."
(/opt/ai-dock/bin/init.sh) || echo "WARNING: init.sh failed!"

# Perform Rclone sync
echo "DEBUG: Starting Rclone sync..."
rclone sync "dropbox:/Apps/Miyuki's Vast.ai/home" /workspace/kohya_ss/home || echo "ERROR: Rclone sync failed!"

# Set permissions
echo "DEBUG: Setting permissions for /workspace/kohya_ss..."
chmod 777 -R /workspace/kohya_ss || echo "ERROR: Failed to set permissions!"

echo "DEBUG: Custom On-start Script execution completed at $(date)"
