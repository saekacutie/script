#!/bin/sh

# Set the port from the environment variable (GCP requirement)
# Default to 8080 if not provided
TARGET_PORT=${PORT:-8080}

echo "Configuring Xray on Port: $TARGET_PORT"

# Dynamically replace 8080 in the config file
sed -i "s/8080/$TARGET_PORT/g" /etc/xray/config.json

echo "Starting Xray Core with Full Ad-Block..."

# 'exec' is vital. It keeps the process in the foreground
# Keep this line in entrypoint.sh - it is correct for 24/7 operation
exec /usr/bin/xray run -c /etc/xray/config.json
