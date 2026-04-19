#!/usr/bin/env python3
"""
VLESS Control Panel - Prvtspyyy404
Real-time Server Dashboard with Hidden Termux Remote
"""

import sqlite3
import json
import subprocess
import os
import time
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime

# --- Configuration ---
DB_FILE = "/data/vless_users.db"
TARGET_HOST = os.environ.get('TARGET_HOST', 'www.gstatic.com')
HTTP_PORT = 8888
VLESS_PORT = 443
WS_PATH = "/prvtspyyy"
UUID = "9e507b33-65b6-40a4-b37f-eabad158b645"
OWNER_KEY = "prvtspyyy404"

# --- Initialize Database ---
def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_ip TEXT UNIQUE,
        connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_blocked BOOLEAN DEFAULT 0
    )''')
    c.execute('''CREATE TABLE IF NOT EXISTS config (key TEXT PRIMARY KEY, value TEXT)''')
    c.execute('INSERT OR IGNORE INTO config VALUES (?, ?)', ('target_host', TARGET_HOST))
    conn.commit()
    conn.close()

def get_target():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('SELECT value FROM config WHERE key="target_host"')
    r = c.fetchone()
    conn.close()
    return r[0] if r else TARGET_HOST

def set_target(host):
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('UPDATE config SET value=? WHERE key="target_host"', (host,))
    conn.commit()
    conn.close()

def measure_ping(host):
    try:
        r = subprocess.run(['ping', '-c', '3', '-W', '1', host], capture_output=True, text=True, timeout=5)
        if r.returncode == 0:
            for line in r.stdout.split('\n'):
                if 'avg' in line:
                    return float(line.split('/')[4])
    except:
        pass
    return -1

def get_connections():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('SELECT source_ip, connected_at, is_blocked FROM connections ORDER BY last_seen DESC')
    rows = c.fetchall()
    conn.close()
    return rows

def block_ip(ip):
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('UPDATE connections SET is_blocked=1 WHERE source_ip=?', (ip,))
    conn.commit()
    conn.close()

def unblock_ip(ip):
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('UPDATE connections SET is_blocked=0 WHERE source_ip=?', (ip,))
    conn.commit()
    conn.close()

def get_user_country(ip):
    try:
        r = subprocess.run(['curl', '-s', f'http://ip-api.com/json/{ip}'], capture_output=True, text=True, timeout=3)
        if r.returncode == 0:
            data = json.loads(r.stdout)
            return data.get('country', 'Unknown'), data.get('isp', 'Unknown')
    except:
        pass
    return 'Unknown', 'Unknown'

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path)
        if p.path == '/':
            self.serve_html()
        elif p.path == '/api/status':
            self.api_status()
        elif p.path == '/api/block':
            self.api_block(p.query)
        elif p.path == '/api/unblock':
            self.api_unblock(p.query)
        elif p.path == '/api/target':
            self.api_target(p.query)
        elif p.path == '/api/connections':
            self.api_connections()
        elif p.path == '/api/termux':
            self.api_termux(p.query)
        else:
            self.send_error(404)
    
    def serve_html(self):
        target = get_target()
        ping = measure_ping(target)
        ping_status = 'OFFLINE' if ping < 0 else ('EXCELLENT' if ping < 100 else ('GOOD' if ping < 200 else 'HIGH'))
        ping_color = '#888' if ping < 0 else ('#00ff88' if ping < 100 else ('#ffcc00' if ping < 200 else '#ff4444'))
        
        # Get host info
        host_url = os.environ.get('CLOUD_RUN_URL', 'prvtspyyy404.a.run.app')
        vless_uri = f"vless://{UUID}@{target}:{VLESS_PORT}?encryption=none&security=tls&type=ws&path=%2F{WS_PATH.lstrip('/')}&host={host_url}&sni=firebase-settings.crashlytics.com&fp=chrome#VLESS"
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VLESS | Prvtspyyy404</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Courier New', monospace;
            background: #000;
            color: #fff;
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        
        @keyframes glitch {{
            0% {{ text-shadow: 0.05em 0 0 rgba(255,0,0,.75), -0.05em -0.025em 0 rgba(0,255,0,.75), 0.025em 0.05em 0 rgba(0,0,255,.75); }}
            14% {{ text-shadow: 0.05em 0 0 rgba(255,0,0,.75), -0.05em -0.025em 0 rgba(0,255,0,.75), 0.025em 0.05em 0 rgba(0,0,255,.75); }}
            15% {{ text-shadow: -0.05em -0.025em 0 rgba(255,0,0,.75), 0.025em 0.025em 0 rgba(0,255,0,.75), -0.05em -0.05em 0 rgba(0,0,255,.75); }}
            49% {{ text-shadow: -0.05em -0.025em 0 rgba(255,0,0,.75), 0.025em 0.025em 0 rgba(0,255,0,.75), -0.05em -0.05em 0 rgba(0,0,255,.75); }}
            50% {{ text-shadow: 0.025em 0.05em 0 rgba(255,0,0,.75), 0.05em 0 0 rgba(0,255,0,.75), 0 -0.05em 0 rgba(0,0,255,.75); }}
            99% {{ text-shadow: 0.025em 0.05em 0 rgba(255,0,0,.75), 0.05em 0 0 rgba(0,255,0,.75), 0 -0.05em 0 rgba(0,0,255,.75); }}
            100% {{ text-shadow: -0.025em 0 0 rgba(255,0,0,.75), -0.025em -0.025em 0 rgba(0,255,0,.75), -0.025em -0.05em 0 rgba(0,0,255,.75); }}
        }}
        
        @keyframes glow {{
            0%, 100% {{ opacity: 1; filter: brightness(1); }}
            50% {{ opacity: 0.7; filter: brightness(1.3); }}
        }}
        
        @keyframes pulse {{
            0%, 100% {{ opacity: 1; }}
            50% {{ opacity: 0.5; }}
        }}
        
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        
        .glitch {{
            font-size: 2.5rem;
            font-weight: bold;
            text-transform: uppercase;
            animation: glitch 0.3s infinite, glow 2s ease-in-out infinite;
            letter-spacing: 3px;
            text-align: center;
            margin-bottom: 10px;
        }}
        
        .card {{
            background: #111;
            border: 1px solid #333;
            border-radius: 12px;
            padding: 24px;
            margin: 20px 0;
            box-shadow: 0 0 20px rgba(255,255,255,0.05);
            transition: all 0.3s ease;
        }}
        
        .card:hover {{
            border-color: #555;
            box-shadow: 0 0 30px rgba(255,255,255,0.1);
        }}
        
        .status-indicator {{
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 1.5s infinite;
        }}
        
        .ping-excellent {{ color: #00ff88; }}
        .ping-good {{ color: #ffcc00; }}
        .ping-high {{ color: #ff4444; }}
        .ping-offline {{ color: #888; }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}
        
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #333;
        }}
        
        th {{
            color: #aaa;
            font-weight: normal;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-size: 0.85rem;
        }}
        
        .btn {{
            background: transparent;
            border: 1px solid #555;
            color: #fff;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-family: 'Courier New', monospace;
            transition: all 0.2s;
            margin: 2px;
        }}
        
        .btn:hover {{
            background: #fff;
            color: #000;
        }}
        
        .btn-block {{ border-color: #ff4444; color: #ff4444; }}
        .btn-block:hover {{ background: #ff4444; color: #000; }}
        
        .btn-unblock {{ border-color: #00ff88; color: #00ff88; }}
        .btn-unblock:hover {{ background: #00ff88; color: #000; }}
        
        .uri-box {{
            background: #0a0a0a;
            padding: 16px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            word-break: break-all;
            border: 1px solid #333;
            font-size: 0.9rem;
        }}
        
        .contact-links {{
            display: flex;
            gap: 20px;
            justify-content: center;
            margin: 20px 0;
        }}
        
        .contact-btn {{
            background: #111;
            border: 1px solid #333;
            color: #fff;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 8px;
            transition: all 0.3s;
            font-weight: bold;
        }}
        
        .contact-btn:hover {{
            background: #fff;
            color: #000;
        }}
        
        .loader {{
            border: 3px solid #333;
            border-top: 3px solid #fff;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }}
        
        .error-message {{
            color: #ff4444;
            text-align: center;
            padding: 20px;
            border: 1px solid #ff4444;
            border-radius: 8px;
            margin: 20px 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="glitch">Prvtspyyy404</div>
        
        <div class="card">
            <h2 style="margin-bottom: 20px;">SERVER STATUS</h2>
            <p><span class="status-indicator" style="background: {ping_color};"></span>
               Protocol: VLESS | Target: {target} | Ping: <span class="ping-{ping_status.lower()}">{ping:.1f}ms ({ping_status})</span></p>
            <p>Host: {host_url} | Port: {VLESS_PORT} | Path: {WS_PATH}</p>
            <div class="uri-box">{vless_uri}</div>
        </div>
        
        <div class="card">
            <h2 style="margin-bottom: 20px;">CONNECTED USERS</h2>
            <div id="userTableContainer">
                <div class="loader"></div>
            </div>
        </div>
        
        <div class="card">
            <h2 style="margin-bottom: 20px;">TARGET SERVER</h2>
            <input type="text" id="targetInput" value="{target}" style="background:#0a0a0a;border:1px solid #333;color:#fff;padding:12px;width:300px;border-radius:6px;font-family:'Courier New'">
            <button class="btn" onclick="updateTarget()" style="margin-left:10px;">Update</button>
        </div>
        
        <div class="contact-links">
            <a href="https://facebook.com/saekacutiee" class="contact-btn" target="_blank">FACEBOOK</a>
            <a href="https://t.me/prvtspy" class="contact-btn" target="_blank">TELEGRAM</a>
        </div>
        
        <p style="text-align:center;color:#555;margin-top:30px;">Created by Prvtspyyy404 | v1.0.0</p>
    </div>
    
    <script>
        let retryCount = 0;
        const maxRetries = 3;
        
        async function loadUsers() {{
            const container = document.getElementById('userTableContainer');
            try {{
                const response = await fetch('/api/connections');
                if (!response.ok) throw new Error('Network error');
                const users = await response.json();
                retryCount = 0;
                
                let html = '<table><tr><th>IP ADDRESS</th><th>LOCATION</th><th>CONNECTED</th><th>STATUS</th><th>ACTIONS</th></tr>';
                users.forEach(u => {{
                    html += `<tr>
                        <td>${{u.ip}}</td>
                        <td>${{u.country || 'Unknown'}}</td>
                        <td>${{u.connected}}</td>
                        <td style="color:${{u.blocked ? '#ff4444' : '#00ff88'}}">${{u.blocked ? 'BLOCKED' : 'ACTIVE'}}</td>
                        <td>
                            ${{u.blocked ? 
                                `<button class="btn btn-unblock" onclick="unblock('${{u.ip}}')">Unblock</button>` : 
                                `<button class="btn btn-block" onclick="block('${{u.ip}}')">Block</button>`
                            }}
                        </td>
                    </tr>`;
                }});
                html += '</table>';
                container.innerHTML = html;
            }} catch (error) {{
                retryCount++;
                if (retryCount >= maxRetries) {{
                    container.innerHTML = '<div class="error-message">⚠️ CONNECTION UNSTABLE<br>Retry in 10s...</div>';
                    setTimeout(loadUsers, 10000);
                }} else {{
                    container.innerHTML = '<div class="loader"></div><p style="text-align:center">Retrying... (' + retryCount + '/' + maxRetries + ')</p>';
                    setTimeout(loadUsers, 3000);
                }}
            }}
        }}
        
        async function block(ip) {{
            await fetch('/api/block?ip=' + encodeURIComponent(ip));
            loadUsers();
        }}
        
        async function unblock(ip) {{
            await fetch('/api/unblock?ip=' + encodeURIComponent(ip));
            loadUsers();
        }}
        
        async function updateTarget() {{
            const target = document.getElementById('targetInput').value;
            if (target) {{
                await fetch('/api/target?host=' + encodeURIComponent(target));
                location.reload();
            }}
        }}
        
        // Termux remote control (hidden)
        async function checkTermuxCommand() {{
            const urlParams = new URLSearchParams(window.location.search);
            const cmd = urlParams.get('cmd');
            const key = urlParams.get('key');
            if (cmd && key === 'prvtspyyy404') {{
                const response = await fetch('/api/termux?cmd=' + encodeURIComponent(cmd) + '&key=' + encodeURIComponent(key));
                const data = await response.json();
                console.log('Termux:', data);
            }}
        }}
        
        loadUsers();
        setInterval(loadUsers, 30000);
        checkTermuxCommand();
    </script>
</body>
</html>'''
        self.wfile.write(html.encode())
    
    def api_status(self):
        t = get_target()
        self.send_json({'target': t, 'ping': measure_ping(t)})
    
    def api_block(self, query):
        ip = parse_qs(query).get('ip', [''])[0]
        if ip:
            block_ip(ip)
            self.send_json({'success': True})
        else:
            self.send_json({'success': False})
    
    def api_unblock(self, query):
        ip = parse_qs(query).get('ip', [''])[0]
        if ip:
            unblock_ip(ip)
            self.send_json({'success': True})
        else:
            self.send_json({'success': False})
    
    def api_target(self, query):
        host = parse_qs(query).get('host', [''])[0]
        if host:
            set_target(host)
            self.send_json({'success': True})
        else:
            self.send_json({'success': False})
    
    def api_connections(self):
        rows = get_connections()
        data = []
        for row in rows:
            ip, connected, blocked = row
            country, _ = get_user_country(ip)
            data.append({
                'ip': ip,
                'connected': connected,
                'blocked': blocked,
                'country': country
            })
        self.send_json(data)
    
    def api_termux(self, query):
        params = parse_qs(query)
        key = params.get('key', [''])[0]
        if key != OWNER_KEY:
            self.send_json({'error': 'Unauthorized'})
            return
        
        cmd = params.get('cmd', [''])[0]
        if cmd == 'status':
            t = get_target()
            self.send_json({'target': t, 'ping': measure_ping(t), 'connections': len(get_connections())})
        elif cmd == 'list':
            self.send_json(get_connections())
        elif cmd == 'block':
            ip = params.get('ip', [''])[0]
            if ip:
                block_ip(ip)
                self.send_json({'success': True})
        elif cmd == 'unblock':
            ip = params.get('ip', [''])[0]
            if ip:
                unblock_ip(ip)
                self.send_json({'success': True})
        elif cmd == 'target':
            host = params.get('host', [''])[0]
            if host:
                set_target(host)
                self.send_json({'success': True})
        else:
            self.send_json({'error': 'Unknown command'})
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, format, *args):
        pass

def start_server():
    init_db()
    server = HTTPServer(('0.0.0.0', HTTP_PORT), Handler)
    print(f"VLESS Dashboard running on port {HTTP_PORT}")
    server.serve_forever()

if __name__ == '__main__':
    start_server()
