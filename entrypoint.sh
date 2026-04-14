#!/bin/sh
# Overwrite port 8080 in config with the one assigned by GCP
sed -i "s/8080/$PORT/g" /etc/xray/config.json

echo "Server starting on port $PORT..."
# exec ensures Xray handles termination signals correctly
exec /usr/bin/xray run -c /etc/xray/config.json
