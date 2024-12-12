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

# Perform Rclone sync
echo "DEBUG: Preparing to perform Rclone sync..."
if command -v rclone &> /dev/null; then
    echo "DEBUG: Rclone is installed. Starting sync..."
    rclone sync "dropbox:" /workspace/kohya_ss || echo "ERROR: Rclone sync failed!"
else
    echo "ERROR: Rclone is not installed or not found in PATH."
fi
echo "DEBUG: Rclone sync completed."

# Initialize environment
echo "DEBUG: Initializing environment..."
(set +e; /opt/ai-dock/bin/init.sh; set -e) || echo "WARNING: init.sh failed!"
echo "DEBUG: Environment initialization completed. Continuing script..."

# Final debug
echo "DEBUG: Custom On-start Script execution completed at $(date)"
