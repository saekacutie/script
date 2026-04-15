#!/bin/sh
# CLOUD RUN STABILIZER
LISTENING_PORT=${PORT:-8080}

echo "AD-BLOCKER: Sinking YT/FB ad domains..."

# Only replace the port on the line that defines the main inbound
sed -i "0,/\"port\": 8080/s/\"port\": 8080/\"port\": $LISTENING_PORT/" /etc/xray/config.json

# CRITICAL: Verify the config is valid before starting
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "FATAL: Config Error. Check JSON syntax."
    exit 1
fi

echo "SYSTEM: Starting Xray on Port $LISTENING_PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
