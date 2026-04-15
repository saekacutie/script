#!/bin/sh
LISTENING_PORT=${PORT:-8080}
# Replace the unique 9999 placeholder only
sed -i "s/9999/$LISTENING_PORT/" /etc/xray/config.json

# PRE-FLIGHT CHECK
/usr/bin/xray test -c /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "JSON SYNTAX ERROR DETECTED"
    exit 1
fi

exec /usr/bin/xray run -c /etc/xray/config.json
