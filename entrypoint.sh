#!/bin/sh
# FAIL-SAFE ENTRYPOINT
LISTENING_PORT=${PORT:-8080}

echo "AD-BLOCKER: Initializing YouTube/Facebook filtering..."

# Target ONLY the line with port 8080 to prevent conflicts with port 10007
sed -i "s/\"port\": 8080/\"port\": $LISTENING_PORT/" /etc/xray/config.json

# PRE-FLIGHT CHECK: Verify JSON is valid
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "ERROR: Invalid config. Check JSON syntax."
    exit 1
fi

echo "SYSTEM: Xray starting on Port $LISTENING_PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
