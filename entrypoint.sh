#!/bin/sh
# Dynamic port configuration for Google Cloud Run
export PORT=${PORT:-8080}
sed -i "s/8080/$PORT/g" /etc/xray/config.json

echo "[*] Starting VLESS server on port: $PORT"
echo "[*] Configuration file: /etc/xray/config.json"

# Start dashboard server in background
echo "[*] Starting dashboard on port 8081"
python3 /server.py &
DASHBOARD_PID=$!

# Start Xray
echo "[*] Starting Xray VLESS core..."
/usr/bin/xray run -c /etc/xray/config.json
