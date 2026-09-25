#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "[ERROR] Run this utility as root."
  exit 1
fi

show_status() {
  echo "==== Service status ===="
  systemctl --no-pager status nginx wg-quick@wg0 openvpn strongswan udpgw --lines=25 || true
  echo "==== Port scan ===="
  ss -tulpn | grep -E ':80|:443|:1194|:51820|:500|:4500|:7300' || true
  echo "==== Midnight restart timer ===="
  systemctl --no-pager status vpnfront-restart.timer --lines=8 || true
}

show_protocols() {
  echo "==== Protocol summary ===="
  /usr/local/bin/vpn-status-report || true
}

check_cert() {
  /usr/local/bin/vpn-cert-check "${DOMAIN:-vpn.example.com}" 443 || true
}

show_adblock() {
  echo "==== VPN DNS ad blocking ===="
  if [[ -f /var/lib/vpnfront/adblock.json ]]; then
    jq . /var/lib/vpnfront/adblock.json
  else
    echo "Ad-block state is not initialized."
  fi
  systemctl --no-pager status dnsmasq vpn-adblock-update.timer --lines=8 || true
}

toggle_adblock() {
  local choice="${1:-}"
  case "$choice" in
    on)
      printf 'addn-hosts=/var/lib/vpnfront/ads.hosts\n' >/etc/dnsmasq.d/vpnfront-adblock.conf
      dnsmasq --test && systemctl reload dnsmasq
      jq '.enabled = true' /var/lib/vpnfront/adblock.json >/var/lib/vpnfront/adblock.json.tmp && mv /var/lib/vpnfront/adblock.json.tmp /var/lib/vpnfront/adblock.json
      ;;
    off)
      rm -f /etc/dnsmasq.d/vpnfront-adblock.conf
      dnsmasq --test && systemctl reload dnsmasq
      jq '.enabled = false' /var/lib/vpnfront/adblock.json >/var/lib/vpnfront/adblock.json.tmp && mv /var/lib/vpnfront/adblock.json.tmp /var/lib/vpnfront/adblock.json
      ;;
    *) echo "Usage: $0 adblock {status|on|off}"; return 1 ;;
  esac
  show_adblock
}

restart_all() {
  systemctl restart nginx wg-quick@wg0 openvpn strongswan udpgw || true
  echo "Services restarted."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    status) show_status; exit 0 ;;
    protocols) show_protocols; exit 0 ;;
    cert) check_cert; exit 0 ;;
    restart) restart_all; exit 0 ;;
    adblock) toggle_adblock "${2:-}"; exit $? ;;
    *) echo "Usage: $0 {status|protocols|cert|restart}"; exit 1 ;;
  esac
done

cat <<'MENU'
VPN Management Console
1) Show service status
2) Show protocol summary
3) Check domain certificate handshake
4) Restart all services
5) Show VPN DNS ad-block status
6) Enable VPN DNS ad blocking
7) Disable VPN DNS ad blocking
0) Exit
MENU

while true; do
  printf 'Select option: '
  read -r choice || break
  case "$choice" in
    1) show_status ;;
    2) show_protocols ;;
    3) check_cert ;;
    4) restart_all ;;
    5) show_adblock ;;
    6) toggle_adblock on ;;
    7) toggle_adblock off ;;
    0) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
done
