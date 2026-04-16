#!/bin/sh
# Inject the dynamic GCP port into config
sed -i "s/8080/$PORT/g" /etc/xray/config.json

echo "System Keep-Alive: Active"
exec /usr/bin/xray run -c /etc/xray/config.json
