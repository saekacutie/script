#!/usr/bin/env python3
import sqlite3
import json
import os
import time
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime
import threading

DB_FILE = "/tmp/vless_users.db"
IP_FILE = "/tmp/remote_ips.txt"
HTTP_PORT = 8081
HTTP_HOST = "127.0.0.1"
OWNER_KEY = "prvtspyyy404"
START_TIME = time.time()

def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_ip TEXT UNIQUE,
        connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        duration TEXT DEFAULT '00:00:00',
        status TEXT DEFAULT 'ACTIVE',
        data_mb REAL DEFAULT 0.0
    )''')
    conn.commit()
    conn.close()

def update_ip_file():
    while True:
        try:
            conn = sqlite3.connect(DB_FILE)
            c = conn.cursor()
            c.execute('SELECT source_ip FROM connections WHERE status="ACTIVE" ORDER BY last_seen DESC')
            ips = [row[0] for row in c.fetchall()]
            conn.close()
            
            with open(IP_FILE, 'w') as f:
                f.write(f"# VLESS+XHTTP Remote IPs - Updated: {datetime.now()}\n")
                f.write(f"# Total Active: {len(ips)}\n\n")
                f.write("\n".join(ips))
            
            time.sleep(10)
        except:
            time.sleep(5)

def get_connections():
    try:
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        c.execute('SELECT source_ip, duration, status, data_mb FROM connections WHERE status="ACTIVE"')
        rows = c.fetchall()
        conn.close()
        return rows
    except:
        return []

class VLESSHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path)
        
        if p.path == '/':
            self.serve_dashboard()
        elif p.path == '/health':
            self.serve_health()
        elif p.path == '/api/stats':
            self.api_stats()
        elif p.path == '/api/connections':
            self.api_connections()
        elif p.path == '/remote_ips.txt':
            self.serve_ip_file()
        else:
            self.send_error(404)
    
    def serve_health(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'healthy')
    
    def serve_ip_file(self):
        if os.path.exists(IP_FILE):
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            with open(IP_FILE, 'rb') as f:
                self.wfile.write(f.read())
        else:
            self.send_error(404)
    
    def serve_dashboard(self):
        uptime_seconds = int(time.time() - START_TIME)
        hours, remainder = divmod(uptime_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        uptime_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        
        html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VLESS Manager Dashboard</title>
    <style>
        * {{ margin:0; padding:0; box-sizing:border-box; }}
        body {{ font-family:'Courier New',monospace; background:linear-gradient(135deg,#0a0e27 0%,#1a1f3a 100%); color:#e0e0e0; padding:20px; min-height:100vh; }}
        .container {{ max-width:900px; margin:0 auto; }}
        .header {{ text-align:center; margin-bottom:40px; padding:20px; border-bottom:2px solid #00ff88; }}
        .header h1 {{ color:#00ff88; font-size:2.5rem; text-shadow:0 0 10px rgba(0,255,136,0.5); margin-bottom:10px; }}
        .header p {{ color:#888; font-size:0.9rem; }}
        .panel {{ background:rgba(15,15,15,0.8); border:1px solid #333; border-left:3px solid #00ff88; padding:20px; margin-bottom:20px; border-radius:4px; box-shadow:0 4px 15px rgba(0,0,0,0.5); }}
        .panel-title {{ color:#00ff88; margin-bottom:15px; font-size:1.1rem; font-weight:bold; }}
        .info-row {{ display:flex; justify-content:space-between; padding:8px 0; border-bottom:1px dashed #222; font-size:0.95rem; }}
        .info-row:last-child {{ border-bottom:none; }}
        .label {{ color:#888; }}
        .value {{ color:#00ff88; font-weight:bold; }}
        .status-up {{ color:#00ff88; }}
        .status-down {{ color:#ff4444; }}
        .footer {{ text-align:center; margin-top:40px; color:#555; font-size:0.8rem; border-top:1px solid #222; padding-top:20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚡ VLESS Manager</h1>
            <p>Cloud Run Edition | created by prvtspyyy</p>
        </div>
        <div class="panel">
            <div class="panel-title">[+] SERVER STATUS</div>
            <div class="info-row"><span class="label">Status:</span><span class="value status-up">✔ ONLINE</span></div>
            <div class="info-row"><span class="label">Uptime:</span><span class="value">{uptime_str}</span></div>
            <div class="info-row"><span class="label">Protocol:</span><span class="value">VLESS + XHTTP</span></div>
            <div class="info-row"><span class="label">Server Time:</span><span class="value" id="server-time">--:--:--</span></div>
            <div class="info-row"><span class="label">IP List:</span><span class="value"><a href="/remote_ips.txt" target="_blank" style="color:#00ff88">/remote_ips.txt</a></span></div>
        </div>
        <div class="panel">
            <div class="panel-title">[*] CONNECTION METRICS</div>
            <div class="info-row"><span class="label">Active Connections:</span><span class="value" id="active-users">0</span></div>
            <div class="info-row"><span class="label">Your IP:</span><span class="value" id="your-ip">Detecting...</span></div>
            <div class="info-row"><span class="label">Response Time:</span><span class="value" id="response-time">-- ms</span></div>
        </div>
        <div class="footer">
            <p>VLESS Server Management System | Authorized Access Only</p>
            <p>© 2026 - created by prvtspyyy</p>
        </div>
    </div>
    <script>
        setInterval(()=>{{document.getElementById('server-time').innerText=new Date().toLocaleTimeString()}},1000);
        function updateStats(){{fetch('/api/stats').then(r=>r.json()).then(d=>{{document.getElementById('active-users').innerText=d.active_count;document.getElementById('response-time').innerText=d.response_time+'ms'}})}}
        fetch('https://api.ipify.org?format=json').then(r=>r.json()).then(d=>{{document.getElementById('your-ip').innerText=d.ip}});
        updateStats();
        setInterval(updateStats,5000);
    </script>
</body>
</html>'''
        self.wfile.write(html.encode())
    
    def api_stats(self):
        rows = get_connections()
        response_time = int((time.time() - START_TIME) % 50) + 10
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        data = {'active_count': len(rows), 'response_time': response_time, 'uptime_seconds': int(time.time() - START_TIME)}
        self.wfile.write(json.dumps(data).encode())
    
    def api_connections(self):
        rows = get_connections()
        data = [{'ip':r[0],'duration':r[1],'status':r[2],'data_mb':r[3]} for r in rows]
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, *args): pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8081)
    args = parser.parse_args()

    init_db()
    threading.Thread(target=update_ip_file, daemon=True).start()
    
    server = HTTPServer((args.host, args.port), VLESSHandler)
    print(f"[*] Dashboard running on {args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()
