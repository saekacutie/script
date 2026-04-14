#!/bin/sh
# Default to 8080 if $PORT is not provided (local testing)
LISTENING_PORT=${PORT:-8080}

# Replace the placeholder with the actual port assigned by Cloud Run
sed -i "s/\"PORT_PLACEHOLDER\"/$LISTENING_PORT/g" /etc/xray/config.json

echo "Container booting... Binding to Port: $LISTENING_PORT"
echo "Adblock DNS: AdGuard Enabled"

# Exec ensures Xray receives the shutdown signal directly from Cloud Run
exec /usr/bin/xray run -c /etc/xray/config.json
