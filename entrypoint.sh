#!/bin/bash
set -euo pipefail

# 1. Replace port FIRST
sed -i "s/8080/$PORT/g" /etc/xray/config.json
echo "[1] Port set to: $PORT"

# 2. Start dashboard FIRST, bind localhost only
python3 /server.py --host 127.0.0.1 --port 8081 &
sleep 1

# 3. Start IP manager
/ip-manager.sh start &
sleep 1

# 4. START XRAY — THIS MUST LISTEN NOW
echo "[2] Starting Xray Core..."
/usr/bin/xray run -c /etc/xray/config.json &

# 5. WAIT UNTIL PORT IS LISTENING — critical for Cloud Run
echo "[3] Waiting for port $PORT to open..."
until nc -z 127.0.0.1 $PORT; do
  sleep 0.2
done
echo "[✅] SUCCESS: Listening on $PORT — Ready!"

# Keep container alive
wait
