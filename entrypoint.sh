#!/bin/sh

# Use the assigned PORT, or default to 8080 if not set
TARGET_PORT=${PORT:-8080}

echo "Configuring Xray to listen on port: $TARGET_PORT"

# Replace 8080 in the config file with the actual port
# We use 'sed' to update the JSON file dynamically
sed -i "s/8080/$TARGET_PORT/g" /etc/xray/config.json

echo "Starting Xray..."

# 'exec' makes Xray the primary process (PID 1)
# This is what keeps the container alive 24/7
exec /usr/bin/xray run -c /etc/xray/config.json
