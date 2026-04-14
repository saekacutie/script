#!/bin/bash

# ==============================================
#        CONNECTION MONITOR & LOGGER
#           created by prvtspyyy
# ==============================================

# --- Configuration ---
# Get the service URL automatically
SERVICE_NAME="${1:-prvtspyyy404}"
REGION="${2:-us-central1}"
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)' 2>/dev/null | sed 's|https://||')

if [ -z "$SERVICE_URL" ]; then
    echo "Error: Could not find service '$SERVICE_NAME' in region '$REGION'."
    echo "Usage: ./network-monitor.sh [SERVICE_NAME] [REGION]"
    exit 1
fi

# Logging directory
LOG_DIR="$HOME/network-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ping-status-$(date +%Y%m%d).log"

# Ping interval in seconds
INTERVAL=10

# --- Colors for Output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}=========================================${RESET}"
echo -e "${BOLD}${CYAN}   VLESS CONNECTION MONITOR STARTED     ${RESET}"
echo -e "${BOLD}${CYAN}=========================================${RESET}"
echo -e "${CYAN}Target:${RESET} $SERVICE_URL"
echo -e "${CYAN}Log file:${RESET} $LOG_FILE"
echo -e "${CYAN}Ping interval:${RESET} ${INTERVAL}s"
echo -e "${BOLD}${CYAN}=========================================${RESET}"
echo -e "Press Ctrl+C to stop.\n"

# Trap Ctrl+C for a clean exit
trap 'echo -e "\n${BOLD}${YELLOW}Monitoring stopped. Log saved to $LOG_FILE${RESET}"; exit 0' INT

# --- Monitoring Loop ---
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Perform a single ping with a 2-second timeout
    PING_RESULT=$(ping -c 1 -W 2 "$SERVICE_URL" 2>&1)
    
    if [ $? -eq 0 ]; then
        # Extract the ping time (ms)
        PING_TIME=$(echo "$PING_RESULT" | grep -oP 'time=\K[0-9.]+' | head -1)
        STATUS="${GREEN}UP${RESET}"
        LOG_ENTRY="$TIMESTAMP | UP | ${PING_TIME}ms | $SERVICE_URL"
        echo -e "$TIMESTAMP | ${GREEN}UP${RESET}   | ${PING_TIME}ms"
    else
        STATUS="${RED}DOWN${RESET}"
        LOG_ENTRY="$TIMESTAMP | DOWN | N/A | $SERVICE_URL"
        echo -e "$TIMESTAMP | ${RED}DOWN${RESET} | No response"
    fi
    
    # Write to log file
    echo "$LOG_ENTRY" >> "$LOG_FILE"
    
    sleep "$INTERVAL"
done
