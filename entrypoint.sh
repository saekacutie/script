#!/bin/sh
# Change the port 8080 in config to match Google's assigned $PORT
sed -i "s/8080/$PORT/g" /etc/xray/config.json

echo "System starting on port $PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
