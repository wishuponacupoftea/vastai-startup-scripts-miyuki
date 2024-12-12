#!/bin/bash

exec > /var/log/custom_startup.log 2>&1
set -e  # Exit immediately on error
set -x  # Enable command tracing for debugging

echo "DEBUG: Custom On-start Script execution started at $(date)"

# Set up the /workspace/ directory
echo "DEBUG: Checking /workspace/ directory..."
mkdir -p /workspace/
chmod 777 /workspace/

# Set up Rclone configuration
echo "DEBUG: Setting up Rclone configuration..."
mkdir -p /root/.config/rclone
if [ ! -f /root/.config/rclone/rclone.conf ]; then
    echo "DEBUG: Creating Rclone configuration file..."
    cat <<EOF > /root/.config/rclone/rclone.conf
[dropbox]
type = dropbox
token = {"access_token":"$DROPBOX_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}
EOF
else
    echo "DEBUG: Rclone configuration file already exists."
fi

# Start Rclone transfer in the background
echo "DEBUG: Starting Rclone transfer in the background..."
rclone --config /root/.config/rclone/rclone.conf copy dropbox: /workspace/kohya_ss/0_cloud --ignore-existing &
RCLONE_PID=$!

# Start environment initialization in the background
echo "DEBUG: Initializing environment in the background..."
/opt/ai-dock/bin/init.sh &
INIT_PID=$!

# Wait for both Rclone and environment initialization to complete
echo "DEBUG: Waiting for Rclone transfer to complete..."
wait $RCLONE_PID
if [ $? -eq 0 ]; then
    echo "DEBUG: Rclone transfer completed successfully."
else
    echo "ERROR: Rclone transfer encountered an issue."
fi

echo "DEBUG: Waiting for environment initialization to complete..."
wait $INIT_PID
if [ $? -eq 0 ]; then
    echo "DEBUG: Environment initialization completed successfully."
else
    echo "ERROR: Environment initialization encountered an issue."
fi

echo "DEBUG: All tasks completed."
