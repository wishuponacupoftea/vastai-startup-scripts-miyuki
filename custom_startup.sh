#!/bin/bash

# Redirect all output (stdout and stderr) to a log file for debugging
exec > /var/log/custom_startup.log 2>&1
set -x  # Enable command tracing for debugging

echo "DEBUG: Custom On-start Script execution started at $(date)"

# Ensure /workspace/ directory exists (MUST COME FIRST)
echo "DEBUG: Checking /workspace/ directory..."
if [ ! -d "/workspace/" ]; then
    echo "DEBUG: /workspace/ directory does not exist. Creating it now..."
    mkdir -p /workspace/
    chmod 777 /workspace/
else
    echo "DEBUG: /workspace/ directory already exists."
fi

# Step 1: Initialize environment
echo "DEBUG: Initializing environment..."
/opt/ai-dock/bin/init.sh || echo "WARNING: init.sh failed!"

# Step 2: Install rclone
echo "DEBUG: Installing rclone..."
curl https://rclone.org/install.sh | bash || echo "ERROR: rclone installation failed!"

# Step 3: Verify Rclone
echo "DEBUG: Verifying Rclone binary..."
rclone version || echo "ERROR: Rclone not installed or accessible!"

# Step 4: Create rclone.conf if not already present
echo "DEBUG: Checking for existing rclone configuration..."
mkdir -p /root/.config/rclone
if [ ! -f /root/.config/rclone/rclone.conf ]; then
    echo "DEBUG: Creating new rclone configuration file..."
    if [ -z "$DROPBOX_TOKEN" ]; then
        echo "ERROR: DROPBOX_TOKEN is not set. Exiting!"
        exit 1
    fi
    cat <<EOF > /root/.config/rclone/rclone.conf
[dropbox]
type = dropbox
token = {"access_token": "${DROPBOX_TOKEN}", "token_type": "bearer"}
EOF
else
    echo "DEBUG: rclone.conf already exists. Skipping creation."
fi

# Step 5: Perform initial sync from Dropbox to server
echo "DEBUG: Starting Rclone sync..."
rclone sync "dropbox:/Apps/Miyuki's Vast.ai/home" /workspace/kohya_ss/home || echo "ERROR: Rclone sync failed!"

# Step 6: Set permissions for the kohya_ss directory
echo "DEBUG: Setting permissions for /workspace/kohya_ss..."
chmod 777 -R /workspace/kohya_ss || echo "ERROR: Failed to set permissions!"
echo "DEBUG: Permissions updated for /workspace/kohya_ss."

# Final Step: Confirm completion
echo "DEBUG: Custom On-start Script execution completed at $(date)"