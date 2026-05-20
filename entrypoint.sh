#!/bin/sh
sed -i "s/8080/$PORT/g" /etc/xray/config.json

# Start all services
python3 /server.py &
/ip-manager.sh start &

echo "Starting Xray on Dynamic Port: $PORT"
/usr/bin/xray run -c /etc/xray/config.json
