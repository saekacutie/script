#!/bin/sh
# CLOUD RUN PORT STABILIZER
LISTENING_PORT=${PORT:-8080}

echo "AD-BLOCKER: Initializing high-performance routing rules..."

# Use a more specific sed to only target the FIRST port entry (8080)
# This prevents it from messing up the 8081 fallback port
sed -i "0,/\"port\": 8080/s/\"port\": 8080/\"port\": $LISTENING_PORT/" /etc/xray/config.json

echo "SYSTEM: Xray starting on Port $LISTENING_PORT..."

# Run Xray and pipe logs to standard output so they show up in Cloud Run logs
exec /usr/bin/xray run -c /etc/xray/config.json
