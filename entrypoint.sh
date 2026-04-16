#!/bin/sh

# 1. Get the port from GCP or default to 8080
TARGET_PORT=${PORT:-8080}

# 2. Only run sed if the config exists to prevent startup crash
if [ -f "/etc/xray/config.json" ]; then
    echo "Updating Port to $TARGET_PORT"
    sed -i "s/8080/$TARGET_PORT/g" /etc/xray/config.json
else
    echo "ERROR: config.json not found in /etc/xray/"
    exit 1
fi

echo "Starting Xray Core..."

# 3. Use 'exec' to hand over PID 1 to Xray
exec /usr/bin/xray run -c /etc/xray/config.json
