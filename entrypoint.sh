#!/bin/sh
# Start the web dashboard on port 8081
python3 /usr/bin/server.py &
# Start Xray on port 8080
exec /usr/bin/xray run -c /etc/xray/config.json
