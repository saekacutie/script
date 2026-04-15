#!/bin/sh

# Default to 8080 if Cloud Run doesn't provide a PORT
LISTENING_PORT=${PORT:-8080}

# STABILIZER: Specifically target only the 8080 port in the config
# This prevents it from accidentally touching the 8081 fallback port.
sed -i "s/\"port\": 8080/\"port\": $LISTENING_PORT/g" /etc/xray/config.json

echo "SYSTEM: Xray binding to Port $LISTENING_PORT..."
echo "SYSTEM: Initializing high-speed routing..."

# Start Xray
exec /usr/bin/xray run -c /etc/xray/config.json
