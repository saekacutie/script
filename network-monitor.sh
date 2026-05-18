#!/bin/bash
# Network monitoring and connection tracking

SERVICE_NAME="${1:-vless-ws}"
REGION="${2:-us-central1}"
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)' 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
    echo "[!] Error: Could not find service '$SERVICE_NAME' in region '$REGION'"
    exit 1
fi

LOG_DIR="$HOME/vless-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/status-$(date +%Y%m%d).log"
INTERVAL=30

echo "[*] VLESS Network Monitor Started"
echo "[*] Target: $SERVICE_URL"
echo "[*] Log file: $LOG_FILE"
echo ""

trap 'echo "[*] Monitor stopped"; exit 0' INT

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Health check
    RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{http_code}" --max-time 5 "${SERVICE_URL}/health" 2>/dev/null)
    
    if [ -n "$RESULT" ]; then
        TIME=$(echo "$RESULT" | cut -d'|' -f1)
        CODE=$(echo "$RESULT" | cut -d'|' -f2)
        TIME_MS=$(echo "$TIME * 1000" | bc 2>/dev/null | cut -d'.' -f1)
        
        if [ "$CODE" = "200" ]; then
            STATUS="✔ UP"
            COLOR='\033[0;32m'
        else
            STATUS="⚠ WARN"
            COLOR='\033[1;33m'
        fi
        
        LOG_ENTRY="$TIMESTAMP | $STATUS | HTTP $CODE | ${TIME_MS}ms"
        echo -e "${COLOR}$LOG_ENTRY${RESET}"
        echo "$LOG_ENTRY" >> "$LOG_FILE"
    else
        LOG_ENTRY="$TIMESTAMP | ✘ DOWN | Timeout"
        echo -e "\033[0;31m$LOG_ENTRY${RESET}"
        echo "$LOG_ENTRY" >> "$LOG_FILE"
    fi
    
    sleep "$INTERVAL"
done
