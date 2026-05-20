#!/bin/bash
set -e

# Replace port correctly
sed -i "s/8080/$PORT/g" /etc/xray/config.json

# Start IP manager
/ip-manager.sh start &

# Start dashboard ONLY on localhost (no conflict)
python3 /server.py --port=8081 --host=127.0.0.1 &

# Wait for files ready
sleep 2

# Start Xray — bind ALL interfaces
echo "Starting Xray on port: $PORT"
/usr/bin/xray run -c /etc/xray/config.json
