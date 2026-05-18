#!/bin/bash
set -e

# ============================================
#  VLESS WS TLS GCP AUTO DEPLOYER
#  created by prvtspyyy - CLOUD RUN EDITION
# ============================================

# --- ANSI Colors ---
BOLD='\033[1m'
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LCYAN='\033[1;36m'

C_SUCCESS="${BOLD}${LGREEN}"
C_ERROR="${BOLD}${LRED}"
C_WARN="${BOLD}${LYELLOW}"
C_INFO="${BOLD}${LCYAN}"
C_HEADER="${BOLD}${LCYAN}"
C_ACCENT="${BOLD}${LBLUE}"
C_PLAIN="${BOLD}${WHITE}"

# --- Banner ---
echo ""
echo -e "${C_HEADER}╔════════════════════════════════════════════════╗${RESET}"
echo -e "${C_HEADER}║${RESET}  ${C_PLAIN}VLESS WebSocket TLS - Cloud Run${RESET}          ${C_HEADER}║${RESET}"
echo -e "${C_HEADER}║${RESET}  ${CYAN}Ultra-Stealth Edition${RESET}                   ${C_HEADER}║${RESET}"
echo -e "${C_HEADER}║${RESET}  ${CYAN}created by prvtspyyy${RESET}                     ${C_HEADER}║${RESET}"
echo -e "${C_HEADER}╚════════════════════════════════════════════════╝${RESET}"
echo ""

# --- Project Verification ---
echo -e "${C_HEADER}[*] Verifying GCP Setup${RESET}"

ACCOUNT=$(gcloud auth list --format="value(account)" 2>/dev/null | head -1)
if [ -z "$ACCOUNT" ]; then
    echo -e "${C_ERROR}[✘] Not logged in${RESET}"
    echo "Run: gcloud auth login"
    exit 1
fi
echo -e "${C_SUCCESS}[✔] Logged in as: ${BOLD}${ACCOUNT}${RESET}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${C_ERROR}[✘] No project set${RESET}"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi
echo -e "${C_SUCCESS}[✔] Project: ${BOLD}${PROJECT_ID}${RESET}"

# Enable APIs
echo -e "${C_INFO}[*] Enabling APIs...${RESET}"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com --quiet 2>/dev/null
echo -e "${C_SUCCESS}[✔] APIs enabled${RESET}"
echo ""

# --- Region & Service Configuration ---
echo -e "${C_HEADER}[?] Configuration${RESET}"

REGIONS=("us-central1" "us-east1" "asia-east1" "asia-southeast1" "europe-west1")
echo "Available regions:"
for i in "${!REGIONS[@]}"; do
    echo -e "  ${C_ACCENT}[$((i+1))]${RESET} ${REGIONS[$i]}"
done

read -p "$(echo -e "${C_INFO}Select region [1-5] (default: 1):${RESET} ")" REGION_CHOICE
REGION="${REGIONS[$((${REGION_CHOICE:-1}-1))]}"
echo -e "${C_SUCCESS}[✔] Region: ${BOLD}${REGION}${RESET}"

read -p "$(echo -e "${C_INFO}Service name [default: vless-ws]:${RESET} ")" SERVICE_INPUT
SERVICE_NAME="${SERVICE_INPUT:-vless-ws}"
SERVICE_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
echo -e "${C_SUCCESS}[✔] Service: ${BOLD}${SERVICE_NAME}${RESET}"

read -p "$(echo -e "${C_INFO}UUID [default: auto]:${RESET} ")" UUID_INPUT
UUID="${UUID_INPUT:-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null)}"
echo -e "${C_SUCCESS}[✔] UUID: ${BOLD}${UUID}${RESET}"

echo -e "${C_HEADER}CPU/Memory Options:${RESET}"
echo -e "  ${C_ACCENT}[1]${RESET} 1 vCPU, 512Mi"
echo -e "  ${C_ACCENT}[2]${RESET} 1 vCPU, 1Gi"
echo -e "  ${C_ACCENT}[3]${RESET} 2 vCPU, 2Gi (recommended)"
echo -e "  ${C_ACCENT}[4]${RESET} 2 vCPU, 4Gi"
read -p "$(echo -e "${C_INFO}Select [1-4] (default: 3):${RESET} ")" CPU_CHOICE

case "${CPU_CHOICE:-3}" in
    1) CPU="1"; MEMORY="512Mi" ;;
    2) CPU="1"; MEMORY="1Gi" ;;
    3) CPU="2"; MEMORY="2Gi" ;;
    4) CPU="2"; MEMORY="4Gi" ;;
    *) CPU="2"; MEMORY="2Gi" ;;
esac
echo -e "${C_SUCCESS}[✔] CPU: ${BOLD}${CPU}${RESET}, Memory: ${BOLD}${MEMORY}${RESET}"
echo ""

# --- Build & Deploy ---
echo -e "${C_HEADER}[*] Building Docker image...${RESET}"
IMAGE="gcr.io/$PROJECT_ID/$SERVICE_NAME"

if gcloud builds submit --tag "$IMAGE" . --quiet 2>&1 | tail -1; then
    echo -e "${C_SUCCESS}[✔] Build successful${RESET}"
else
    echo -e "${C_ERROR}[✘] Build failed${RESET}"
    exit 1
fi

echo -e "${C_HEADER}[*] Deploying to Cloud Run...${RESET}"
gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE" \
    --platform managed \
    --region "$REGION" \
    --allow-unauthenticated \
    --port 8080 \
    --cpu "$CPU" \
    --memory "$MEMORY" \
    --concurrency 1000 \
    --timeout 3600 \
    --min-instances 1 \
    --max-instances 100 \
    --no-cpu-throttling \
    --session-affinity \
    --quiet

if [ $? -eq 0 ]; then
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format='value(status.url)' 2>/dev/null)
    CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')
    
    echo -e "${C_SUCCESS}[✔] Deployment successful${RESET}"
    echo ""
    echo -e "${C_SUCCESS}╔════════════════════════════════════════════════╗${RESET}"
    echo -e "${C_SUCCESS}║${RESET}           ${BOLD}VLESS SERVER DEPLOYED${RESET}              ${C_SUCCESS}║${RESET}"
    echo -e "${C_SUCCESS}╠════════════════════════════════════════════════╣${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Address:${RESET}  ${BOLD}${CLEAN_HOST}${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Port:${RESET}     ${BOLD}443${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}UUID:${RESET}     ${BOLD}${UUID}${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Path:${RESET}     ${BOLD}/prvtspyyy${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Protocol:${RESET}  ${BOLD}VLESS${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Transport:${RESET} ${BOLD}WebSocket (WS)${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Security:${RESET}  ${BOLD}TLS (Auto)${RESET}"
    echo -e "${C_SUCCESS}║${RESET} ${CYAN}Region:${RESET}    ${BOLD}${REGION}${RESET}"
    echo -e "${C_SUCCESS}╠════════════════════════════════════════════════╣${RESET}"
    echo -e "${C_SUCCESS}║${RESET}                                                ${C_SUCCESS}║${RESET}"
    echo -e "${C_SUCCESS}║${RESET}   ${CYAN}VLESS URI:${RESET}                            ${C_SUCCESS}║${RESET}"
    VLESS_URI="vless://${UUID}@${CLEAN_HOST}:443?encryption=none&security=tls&type=ws&path=%2Fprvtspyyy&host=${CLEAN_HOST}&sni=${CLEAN_HOST}&fp=chrome#${SERVICE_NAME}"
    echo -e "${C_SUCCESS}║${RESET}   ${BOLD}${VLESS_URI:0:50}...${RESET}     ${C_SUCCESS}║${RESET}"
    echo -e "${C_SUCCESS}║${RESET}                                                ${C_SUCCESS}║${RESET}"
    echo -e "${C_SUCCESS}╚════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${C_INFO}[*] Dashboard: ${BOLD}https://${CLEAN_HOST}/api/stats${RESET}"
    echo -e "${C_INFO}[*] Health check: ${BOLD}https://${CLEAN_HOST}/health${RESET}"
    echo ""
else
    echo -e "${C_ERROR}[✘] Deployment failed${RESET}"
    exit 1
fi
