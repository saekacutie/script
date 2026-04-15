#!/bin/sh
# PORT STABILIZER
LISTENING_PORT=${PORT:-8080}

echo "SYSTEM: Initializing YouTube/Facebook Ad-Block..."

# Use a unique placeholder '9999' to avoid accidental multi-replaces
sed -i "s/\"port\": 9999/\"port\": $LISTENING_PORT/" /etc/xray/config.json

# CRITICAL: Validate JSON syntax before running
echo "SYSTEM: Validating configuration..."
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "ERROR: JSON Syntax is invalid. Deployment halted."
    exit 1
fi

echo "SYSTEM: Starting Xray on Port $LISTENING_PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
