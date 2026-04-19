#!/bin/sh
python3 /usr/bin/server.py &
exec /usr/bin/xray run -c /etc/xray/config.json
