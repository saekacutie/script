#!/bin/sh
LISTENING_PORT=${PORT:-8080}

# Replace the placeholder 9999 with the Cloud Run port
sed -i "s/9999/$LISTENING_PORT/" /etc/xray/config.json

# PRE-FLIGHT CHECK: Stop if the config is broken
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "FATAL: JSON Syntax Error detected."
    exit 1
fi

echo "SYSTEM: Starting Xray on Port $LISTENING_PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
