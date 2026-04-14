#!/bin/sh
# Replaces 8080 with the actual port assigned by Google Cloud
sed -i "s/8080/$PORT/g" /etc/xray/config.json

echo "Starting Xray on Port: $PORT"
exec /usr/bin/xray run -c /etc/xray/config.json
