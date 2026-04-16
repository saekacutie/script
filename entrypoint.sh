#!/bin/sh

# 1. Replace 8080 with the GCP-assigned port (or default to 8080 if $PORT is empty)
# We use ${PORT:-8080} as a fallback to prevent sed from breaking.
TARGET_PORT=${PORT:-8080}
sed -i "s/8080/$TARGET_PORT/g" /etc/xray/config.json

echo "Starting Xray on Dynamic Port: $TARGET_PORT"

# 2. Use 'exec' to run Xray in the foreground.
# This ensures the container stays alive and responds to GCP's shutdown signals.
exec /usr/bin/xray run -c /etc/xray/config.json
