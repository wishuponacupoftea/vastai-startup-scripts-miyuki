#!/bin/bash

# Redirect all output (stdout and stderr) to a log file for debugging
exec > /var/log/custom_startup.log 2>&1
set -x  # Enable command tracing for debugging

echo "DEBUG: Custom On-start Script execution started at $(date)"
echo "DEBUG: Environment variables at script start:" >> /var/log/custom_startup.log
env >> /var/log/custom_startup.log  # Log all environment variables

# Step 1: Initialize environment
echo "DEBUG: Initializing environment..."
/opt/ai-dock/bin/init.sh || echo "WARNING: init.sh failed!"

# Step 2: Install rclone
echo "DEBUG: Installing rclone..."
curl https://rclone.org/install.sh | bash || echo "ERROR: rclone installation failed!"

# Step 3: Create rclone configuration directory
echo "DEBUG: Creating rclone configuration directory..."
mkdir -p /root/.config/rclone

# Step 4: Create rclone.conf if not already present
echo "DEBUG: Checking for existing rclone configuration..."
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

# Step 5: Verify rclone configuration
echo "DEBUG: Verifying rclone configuration..."
rclone config show || echo "ERROR: rclone configuration verification failed!"

# Step 6: Perform initial sync from Dropbox to server
echo "DEBUG: Starting initial sync from Dropbox to /workspace/kohya_ss/home..."
rclone sync "dropbox:/Apps/Miyuki's Vast.ai/home" /workspace/kohya_ss/home || echo "ERROR: rclone sync failed!"

# Step 7: Set permissions for the kohya_ss directory
echo "DEBUG: Setting permissions for /workspace/kohya_ss..."
chmod 777 -R /workspace/kohya_ss || echo "ERROR: Failed to set permissions!"
echo "DEBUG: Permissions updated for /workspace/kohya_ss."

# Final Step: Confirm completion
echo "DEBUG: Custom On-start Script execution completed at $(date)"
