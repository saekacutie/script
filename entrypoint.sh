#!/bin/sh
# Fallback to 8080 if PORT is not provided by the environment
PORT=${PORT:-8080}

# Strictly replace ONLY the primary inbound port to avoid fallback conflicts
sed -i -E "s/\"port\": *8080,/\"port\": $PORT,/g" /etc/xray/config.json

echo "Xray booting strictly on port $PORT..."
exec /usr/bin/xray run -c /etc/xray/config.json
