#!/bin/sh
# Use the port Cloud Run gives us, or default to 8080
LISTENING_PORT=${PORT:-8080}

# Replace ONLY the first instance of "port": 8080 to avoid touching port 8081
sed -i "0,/\"port\": 8080/s/\"port\": 8080/\"port\": $LISTENING_PORT/" /etc/xray/config.json

echo "AD-BLOCKER: Initializing DNS Sinkhole..."
echo "SYSTEM: Starting Xray on Port $LISTENING_PORT..."

exec /usr/bin/xray run -c /etc/xray/config.json
