#!/bin/bash
SERVICE_NAME="${1:-vless-xhttp}"
REGION="${2:-us-central1}"
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)' 2>/dev/null)
[ -z "$SERVICE_URL" ] && echo "[!] Service not found" && exit 1
LOG_DIR="$HOME/vless-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/status-$(date +%Y%m%d).log"
INTERVAL=30
echo "[*] Monitor started: $SERVICE_URL"
trap 'exit 0' INT
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    RESULT=$(curl -o /dev/null -s -w "%{time_total}|%{http_code}" --max-time 5 "${SERVICE_URL}/health" 2>/dev/null)
    if [ -n "$RESULT" ]; then
        TIME=$(echo "$RESULT" | cut -d'|' -f1)
        CODE=$(echo "$RESULT" | cut -d'|' -f2)
        TIME_MS=$(echo "$TIME*1000" | bc 2>/dev/null | cut -d'.' -f1)
        [ "$CODE" = "200" ] && STATUS="✔ UP" && COLOR="\033[0;32m" || STATUS="⚠ WARN" && COLOR="\033[1;33m"
        LOG_ENTRY="$TIMESTAMP | $STATUS | HTTP $CODE | ${TIME_MS}ms"
    else
        LOG_ENTRY="$TIMESTAMP | ✘ DOWN | Timeout"
        COLOR="\033[0;31m"
    fi
    echo -e "${COLOR}$LOG_ENTRY\033[0m"
    echo "$LOG_ENTRY" >> "$LOG_FILE"
    sleep "$INTERVAL"
done
