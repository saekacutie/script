#!/bin/sh
# Force the port provided by Cloud Run
LISTENING_PORT=${PORT:-8080}

echo "AD-BLOCKER: Activating DNS Sinkhole for YT/FB..."

# Precision replacement to avoid breaking JSON structure
sed -i "s/\"port\": 8080/\"port\": $LISTENING_PORT/" /etc/xray/config.json

# Test the config before starting to ensure no 8080 bind errors
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "ERROR: Configuration test failed. Check the JSON syntax."
    exit 1
fi

echo "SYSTEM: Starting Xray on Port $LISTENING_PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
