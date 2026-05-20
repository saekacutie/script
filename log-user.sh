#!/bin/sh
DB="/tmp/vless_users.db"
[ ! -f "$DB" ] && sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS connections (id INTEGER PRIMARY KEY AUTOINCREMENT,source_ip TEXT UNIQUE,connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,is_blocked BOOLEAN DEFAULT 0);" 2>/dev/null
[ -n "$1" ] && sqlite3 "$DB" "INSERT OR REPLACE INTO connections (source_ip,last_seen) VALUES ('$1',CURRENT_TIMESTAMP);" 2>/dev/null
