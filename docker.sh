#!/bin/bash
set -e
# ==============================================
# TROJAN-GO + OPENRESTY / XHTTP – ULTRA STEALTH
# Dual tunnel deployer for GCP Cloud Shell
# created by prvtspyyy
# ==============================================

# --- ANSI colour definitions ---
BOLD='\033[1m'; RESET='\033[0m'
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[0;37m'
LRED='\033[1;31m'; LGREEN='\033[1;32m'; LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'; LMAGENTA='\033[1;35m'; LCYAN='\033[1;36m'; LWHITE='\033[1;37m'
C_SUCCESS="${BOLD}${LGREEN}"; C_ERROR="${BOLD}${LRED}"
C_WARN="${BOLD}${LYELLOW}"; C_INFO="${BOLD}${LCYAN}"
C_HEADER="${BOLD}${LMAGENTA}"; C_ACCENT="${BOLD}${LBLUE}"; C_PLAIN="${BOLD}${WHITE}"

# --- Mathematical bold converter (UI) ---
math_bold() {
    echo "$1" | sed \
        -e 's/A/𝐀/g' -e 's/B/𝐁/g' -e 's/C/𝐂/g' -e 's/D/𝐃/g' -e 's/E/𝐄/g' \
        -e 's/F/𝐅/g' -e 's/G/𝐆/g' -e 's/H/𝐇/g' -e 's/I/𝐈/g' -e 's/J/𝐉/g' \
        -e 's/K/𝐊/g' -e 's/L/𝐋/g' -e 's/M/𝐌/g' -e 's/N/𝐍/g' -e 's/O/𝐎/g' \
        -e 's/P/𝐏/g' -e 's/Q/𝐐/g' -e 's/R/𝐑/g' -e 's/S/𝐒/g' -e 's/T/𝐓/g' \
        -e 's/U/𝐔/g' -e 's/V/𝐕/g' -e 's/W/𝐖/g' -e 's/X/𝐗/g' -e 's/Y/𝐘/g' \
        -e 's/Z/𝐙/g' -e 's/0/𝟎/g' -e 's/1/𝟏/g' -e 's/2/𝟐/g' -e 's/3/𝟑/g' \
        -e 's/4/𝟒/g' -e 's/5/𝟓/g' -e 's/6/𝟔/g' -e 's/7/𝟕/g' -e 's/8/𝟖/g' -e 's/9/𝟗/g'
}

# --- Rainbow banner ---
rainbow_banner() {
    clear
    echo ""
    echo -e "${BOLD}${LRED}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}                                                                            ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}██████╗ ██████╗ ██╗   ██╗████████╗███████╗██████╗ ██╗   ██╗${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗╚██╗ ██╔╝${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}██████╔╝██████╔╝██║   ██║   ██║   ███████╗██████╔╝ ╚████╔╝ ${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}██╔═══╝ ██╔══██╗╚██╗ ██╔╝   ██║   ╚════██║██╔═══╝   ╚██╔╝  ${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}██║     ██║  ██║ ╚████╔╝    ██║   ███████║██║        ██║   ${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}  ${BOLD}${WHITE}╚═╝     ╚═╝  ╚═╝  ╚═══╝     ╚═╝   ╚══════╝╚═╝        ╚═╝   ${LRED}  ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}                                                                            ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}           ${BOLD}${WHITE}TROJAN-GO + OPENRESTY / XHTTP ULTRA STEALTH SUITE${RESET}        ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}           ${CYAN}Dual tunnel deployment for Cloud Run${RESET}                           ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}║${RESET}           ${CYAN}created by prvtspyyy${RESET}                                           ${BOLD}${LRED}║${RESET}"
    echo -e "${BOLD}${LRED}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# --- Project & API check ---
check_project_and_apis() {
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${C_PLAIN}$(math_bold "API VERIFICATION")${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"

    local APIS=("run.googleapis.com" "cloudbuild.googleapis.com")
    for api in "${APIS[@]}"; do
        echo -ne "${C_INFO}[*]${RESET} Checking $api...\r"
        gcloud services enable "$api" --quiet 2>/dev/null
        echo -e "${C_SUCCESS}[✔]${RESET} $api enabled"
    done
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# --- Common input: region, cpu/memory, service name, password ---
gather_common_config() {
    # Region selection
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${C_PLAIN}$(math_bold "REGION SELECTION")${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e " ${C_ACCENT}[1]${RESET} us-central1"
    echo -e " ${C_ACCENT}[2]${RESET} us-east1"
    echo -e " ${C_ACCENT}[3]${RESET} asia-east1"
    echo -e " ${C_ACCENT}[4]${RESET} asia-southeast1"
    echo -e " ${C_ACCENT}[5]${RESET} europe-west1"
    echo -e " ${C_ACCENT}[6]${RESET} europe-west4"
    read -p "$(echo -e "${C_INFO}[?]${RESET} Select region [1-6] (default: us-central1): ")" REGION_CHOICE
    case "${REGION_CHOICE:-1}" in
        1) REGION="us-central1" ;; 2) REGION="us-east1" ;; 3) REGION="asia-east1" ;;
        4) REGION="asia-southeast1" ;; 5) REGION="europe-west1" ;; 6) REGION="europe-west4" ;;
        *) REGION="us-central1" ;;
    esac
    echo -e "${C_SUCCESS}[✔]${RESET} Region: ${BOLD}${REGION}${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""

    # Service name
    read -p "$(echo -e "${C_INFO}[?]${RESET} Enter service name (default: trojan-xhttp): ")" SERVICE_NAME_INPUT
    SERVICE_NAME="${SERVICE_NAME_INPUT:-trojan-xhttp}"
    SERVICE_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
    if [ -z "$SERVICE_NAME" ]; then SERVICE_NAME="trojan-xhttp"; fi
    echo -e "${C_SUCCESS}[✔]${RESET} Service name: ${BOLD}${SERVICE_NAME}${RESET}"
    echo ""

    # Password / UUID
    read -p "$(echo -e "${C_INFO}[?]${RESET} Enter password/UUID (default: auto-generated): ")" PASSWORD_INPUT
    PASSWORD="${PASSWORD_INPUT:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c16)}"
    echo -e "${C_SUCCESS}[✔]${RESET} Password/UUID: ${BOLD}${PASSWORD}${RESET}"
    echo ""

    # CPU and memory
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${C_PLAIN}$(math_bold "CPU AND MEMORY SELECTION")${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e " ${C_ACCENT}[1]${RESET} 1 vCPU, 512Mi (free tier)"
    echo -e " ${C_ACCENT}[2]${RESET} 1 vCPU, 1Gi"
    echo -e " ${C_ACCENT}[3]${RESET} 2 vCPU, 2Gi"
    echo -e " ${C_ACCENT}[4]${RESET} 2 vCPU, 4Gi (recommended)"
    echo -e " ${C_ACCENT}[5]${RESET} 4 vCPU, 8Gi"
    echo -e " ${C_ACCENT}[6]${RESET} 4 vCPU, 16Gi"
    read -p "$(echo -e "${C_INFO}[?]${RESET} Choose config [1-6] (default: 4): ")" CPU_RAM_CHOICE
    CPU_RAM_CHOICE="${CPU_RAM_CHOICE:-4}"
    case $CPU_RAM_CHOICE in
        1) CPU="1"; MEMORY="512Mi" ;;
        2) CPU="1"; MEMORY="1Gi" ;;
        3) CPU="2"; MEMORY="2Gi" ;;
        4) CPU="2"; MEMORY="4Gi" ;;
        5) CPU="4"; MEMORY="8Gi" ;;
        6) CPU="4"; MEMORY="16Gi" ;;
        *) CPU="2"; MEMORY="4Gi" ;;
    esac
    echo -e "${C_SUCCESS}[✔]${RESET} CPU: ${BOLD}${CPU}${RESET}, Memory: ${BOLD}${MEMORY}${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# --- Deploy Trojan-Go + OpenResty ---
deploy_trojan_go() {
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${C_PLAIN}$(math_bold "TROJAN-GO + OPENRESTY DEPLOYMENT")${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"

    # Fixed path
    WS_PATH="/saeka-tojirp"
    TROJAN_GO_VER="v0.10.6"

    # Build directory
    BUILD_DIR=$(mktemp -d)
    cd "$BUILD_DIR"

    # Trojan-Go config (optimised)
    cat <<EOF > trojan-go-config.json
{
  "run_type": "server",
  "local_addr": "127.0.0.1",
  "local_port": 4433,
  "remote_addr": "0.0.0.0",
  "remote_port": 0,
  "password": ["$PASSWORD"],
  "websocket": {
    "enabled": true,
    "path": "$WS_PATH",
    "host": ""
  },
  "mux": {
    "enabled": true,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "tcp": {
    "fast_open": true,
    "buffer_size": 65536,
    "keepalive_interval": 30
  }
}
EOF

    # Nginx config with decoy + WebSocket + buffer boost
    cat <<'NGINXEOF' > nginx.conf
worker_processes auto;
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    server {
        listen 8080;
        server_name _;

        location / {
            proxy_pass https://DECOY_PLACEHOLDER;
            proxy_ssl_server_name on;
            proxy_set_header Host DECOY_PLACEHOLDER;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_pass_header Set-Cookie;
            proxy_pass_header Server;
        }

        location /saeka-tojirp {
            proxy_pass http://127.0.0.1:4433;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
            proxy_request_buffering off;
            tcp_nodelay on;

            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
        }
    }
}
NGINXEOF
    sed -i "s|DECOY_PLACEHOLDER|$DECOY_DOMAIN|g" nginx.conf

    # Entrypoint
    cat <<'ENTRYEOF' > entrypoint.sh
#!/bin/sh
/usr/local/openresty/bin/openresty -g 'daemon off;' &
exec /usr/local/bin/trojan-go -config /etc/trojan-go/config.json
ENTRYEOF
    chmod +x entrypoint.sh

    # Dockerfile
    cat <<'DOCKEREOF' > Dockerfile
FROM alpine:latest AS trojan-builder
RUN apk add --no-cache curl unzip
ARG TROJAN_GO_VER=v0.10.6
RUN curl -L "https://github.com/p4gefau1t/trojan-go/releases/download/${TROJAN_GO_VER}/trojan-go-linux-amd64.zip" -o /tmp/tgo.zip && \
    unzip /tmp/tgo.zip -d /tmp/tgo && \
    mv /tmp/tgo/trojan-go-linux-amd64/trojan-go /usr/local/bin/trojan-go && \
    chmod +x /usr/local/bin/trojan-go

FROM openresty/openresty:alpine-fat
RUN apk add --no-cache curl
COPY --from=trojan-builder /usr/local/bin/trojan-go /usr/local/bin/trojan-go
COPY trojan-go-config.json /etc/trojan-go/config.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
DOCKEREOF

    IMAGE="gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"

    echo -e "${C_INFO}[*]${RESET} Building container..."
    if ! docker build -t "$IMAGE" . --quiet 2>&1; then
        echo -e "${C_ERROR}[✘]${RESET} Build failed."
        exit 1
    fi
    echo -e "${C_SUCCESS}[✔]${RESET} Build successful"

    echo -e "${C_INFO}[*]${RESET} Pushing image..."
    if ! docker push "$IMAGE" --quiet 2>&1; then
        echo -e "${C_ERROR}[✘]${RESET} Push failed."
        exit 1
    fi
    echo -e "${C_SUCCESS}[✔]${RESET} Push successful"

    echo -e "${C_INFO}[*]${RESET} Deploying to Cloud Run..."
    gcloud run deploy "$SERVICE_NAME" \
        --image "$IMAGE" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port 8080 \
        --cpu "$CPU" \
        --memory "$MEMORY" \
        --concurrency 1 \
        --timeout 3600 \
        --min-instances 1 \
        --max-instances 1 \
        --no-cpu-throttling \
        --session-affinity \
        --quiet

    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format='value(status.url)')
    CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

    echo ""
    echo -e "${C_SUCCESS}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${BOLD}${WHITE}$(math_bold "TROJAN-GO DEPLOYED")${RESET}"
    echo -e "${C_SUCCESS}╠════════════════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Address:${RESET} ${BOLD}${CLEAN_HOST}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Decoy:${RESET} ${BOLD}${DECOY_DOMAIN}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Password:${RESET} ${BOLD}${PASSWORD}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Path:${RESET} ${BOLD}${WS_PATH}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Port:${RESET} 443, Network: ws, TLS: Yes"
    echo -e "${C_SUCCESS}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "Client: trojan-go -remote ${CLEAN_HOST} -password ${PASSWORD} -ws -ws-path ${WS_PATH}"
    cd ~
    rm -rf "$BUILD_DIR"
}

# --- Deploy XHTTP (node-xhttp) ---
deploy_xhttp() {
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${C_PLAIN}$(math_bold "XHTTP (node-xhttp) DEPLOYMENT")${RESET}"
    echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"

    # Use a different service name (append -xhttp)
    XHTTP_SERVICE_NAME="${SERVICE_NAME}-xhttp"

    echo -e "${C_INFO}[*]${RESET} Deploying node-xhttp service..."
    gcloud run deploy "$XHTTP_SERVICE_NAME" \
        --image=node:18-alpine \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port 8080 \
        --cpu "$CPU" \
        --memory "$MEMORY" \
        --timeout 3600 \
        --max-instances 1 \
        --concurrency 1 \
        --no-cpu-throttling \
        --session-affinity \
        --command="npx" \
        --args="node-xhttp" \
        --set-env-vars="PORT=8080,UUID=${PASSWORD},XPATH=/saeka-tojirp,AUTO_ACCESS=true" \
        --quiet

    XHTTP_URL=$(gcloud run services describe "$XHTTP_SERVICE_NAME" --region "$REGION" --format='value(status.url)')
    XHTTP_HOST=$(echo "$XHTTP_URL" | sed 's|https://||')

    echo ""
    echo -e "${C_SUCCESS}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${BOLD}${WHITE}$(math_bold "XHTTP DEPLOYED")${RESET}"
    echo -e "${C_SUCCESS}╠════════════════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Address:${RESET} ${BOLD}${XHTTP_HOST}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}UUID:${RESET} ${BOLD}${PASSWORD}${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Path:${RESET} ${BOLD}/saeka-tojirp${RESET}"
    echo -e "${C_SUCCESS}║${RESET}  ${CYAN}Port:${RESET} 443, Transport: xhttp (HTTP/2), TLS: Yes"
    echo -e "${C_SUCCESS}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "Client: vless://${PASSWORD}@${XHTTP_HOST}:443?encryption=none&security=tls&type=xhttp&host=${XHTTP_HOST}&path=/saeka-tojirp#${XHTTP_SERVICE_NAME}"
}

# --- Main menu ---
main_menu() {
    while true; do
        rainbow_banner
        echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
        echo -e "${C_PLAIN}$(math_bold "MAIN MENU")${RESET}"
        echo -e "${C_HEADER}════════════════════════════════════════════════════════════════════════════${RESET}"
        echo -e "  ${C_ACCENT}[1]${RESET} Deploy Trojan-Go + OpenResty (WebSocket, decoy)"
        echo -e "  ${C_ACCENT}[2]${RESET} Deploy XHTTP (HTTP/2, keepalive, faster)"
        echo -e "  ${C_ACCENT}[3]${RESET} Deploy Both (side-by-side)"
        echo -e "  ${C_ACCENT}[4]${RESET} Exit"
        echo ""
        read -p "$(echo -e "${C_INFO}[?]${RESET} Choose option [1-4]: ")" MENU_CHOICE

        case "$MENU_CHOICE" in
            1)
                check_project_and_apis
                gather_common_config
                read -p "$(echo -e "${C_INFO}[?]${RESET} Decoy domain (e.g. smart.com.ph): ")" DECOY_DOMAIN
                DECOY_DOMAIN="${DECOY_DOMAIN:-smart.com.ph}"
                deploy_trojan_go
                ;;
            2)
                check_project_and_apis
                gather_common_config
                deploy_xhttp
                ;;
            3)
                check_project_and_apis
                gather_common_config
                read -p "$(echo -e "${C_INFO}[?]${RESET} Decoy domain for Trojan-Go (e.g. smart.com.ph): ")" DECOY_DOMAIN
                DECOY_DOMAIN="${DECOY_DOMAIN:-smart.com.ph}"
                deploy_trojan_go
                deploy_xhttp
                ;;
            4)
                echo -e "${C_SUCCESS}[✔]${RESET} Exiting. Goodbye."
                exit 0
                ;;
            *)
                echo -e "${C_WARN}[!]${RESET} Invalid option."
                sleep 1
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Start
main_menu
