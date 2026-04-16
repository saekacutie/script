#!/bin/sh

# Use 8080 if $PORT is not set by the provider
TARGET_PORT=${PORT:-8080}

# Replace the port in the config
# We use a very specific pattern to avoid breaking the JSON
sed -i "s/\"port\": 8080/\"port\": $TARGET_PORT/g" /etc/xray/config.json

echo "Container starting on port $TARGET_PORT"

# Use 'exec' to make Xray PID 1 (prevents crashes/zombies)
exec /usr/bin/xray run -c /etc/xray/config.json
