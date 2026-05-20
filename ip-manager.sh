#!/bin/sh
# Remote IP Manager for Termux
DB="/tmp/vless_users.db"
IP_FILE="/tmp/remote_ips.txt"

case "$1" in
  start)
    # Auto-update IP file in background
    while true; do
      sqlite3 "$DB" "SELECT source_ip FROM connections WHERE status='ACTIVE' ORDER BY last_seen DESC;" 2>/dev/null > "$IP_FILE.tmp"
      mv "$IP_FILE.tmp" "$IP_FILE"
      sleep 10
    done
    ;;
  list)
    echo "=== Active Remote IPs ==="
    cat "$IP_FILE"
    ;;
  count)
    echo "Total Active: $(wc -l < "$IP_FILE")"
    ;;
  block)
    [ -z "$2" ] && echo "Usage: block <IP>" && exit 1
    sqlite3 "$DB" "UPDATE connections SET is_blocked=1, status='BLOCKED' WHERE source_ip='$2';"
    echo "Blocked: $2"
    ;;
  unblock)
    [ -z "$2" ] && echo "Usage: unblock <IP>" && exit 1
    sqlite3 "$DB" "UPDATE connections SET is_blocked=0, status='ACTIVE' WHERE source_ip='$2';"
    echo "Unblocked: $2"
    ;;
  blocked)
    echo "=== Blocked IPs ==="
    sqlite3 "$DB" "SELECT source_ip FROM connections WHERE status='BLOCKED';"
    ;;
  *)
    echo "VLESS+XHTTP IP Manager"
    echo "Usage: $0 [list|count|block <IP>|unblock <IP>|blocked]"
    ;;
esac
