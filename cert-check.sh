#!/usr/bin/env bash
set -Eeuo pipefail

DOMAIN="${1:-${DOMAIN:-vpn.example.com}}"
PORT="${2:-443}"

if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 <domain> [port]" >&2
  exit 2
fi

echo "Testing TLS handshake for ${DOMAIN}:${PORT}"
openssl s_client -connect "${DOMAIN}:${PORT}" -servername "${DOMAIN}" -showcerts </dev/null 2>/tmp/vpn-cert-check.err | sed -n '1,40p'
STATUS=$?
if [[ $STATUS -eq 0 ]]; then
  echo "Handshake: OK"
else
  echo "Handshake: FAIL"
  cat /tmp/vpn-cert-check.err >&2 || true
  exit $STATUS
fi

openssl x509 -in <(openssl s_client -connect "${DOMAIN}:${PORT}" -servername "${DOMAIN}" -showcerts </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | head -n 200) -noout -subject -issuer -dates 2>/dev/null || true
