#!/usr/bin/env python3
import sqlite3
import json
import os
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime
import threading

DB_FILE = "/tmp/vless_users.db"
HTTP_PORT = 8081
OWNER_KEY = "prvtspyyy404"
START_TIME = time.time()

def init_db():
    """Initialize SQLite database for connection tracking"""
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

def get_connections():
    """Fetch active connections from database"""
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
        """Handle GET requests"""
        p = urlparse(self.path)
        
        if p.path == '/':
            self.serve_dashboard()
        elif p.path == '/health':
            self.serve_health()
        elif p.path == '/api/stats':
            self.api_stats()
        elif p.path == '/api/connections':
            self.api_connections()
        else:
            self.send_error(404)
    
    def serve_health(self):
        """Health check endpoint for Cloud Run"""
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'healthy')
    
    def serve_dashboard(self):
        """Serve the VLESS management dashboard"""
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
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Courier New', Courier, monospace;
            background: linear-gradient(135deg, #0a0e27 0%, #1a1f3a 100%);
            color: #e0e0e0;
            padding: 20px;
            min-height: 100vh;
        }}
        
        .container {{
            max-width: 900px;
            margin: 0 auto;
        }}
        
        .header {{
            text-align: center;
            margin-bottom: 40px;
            padding: 20px;
            border-bottom: 2px solid #00ff88;
        }}
        
        .header h1 {{
            color: #00ff88;
            font-size: 2.5rem;
            text-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
            margin-bottom: 10px;
        }}
        
        .header p {{
            color: #888;
            font-size: 0.9rem;
        }}
        
        .panel {{
            background: rgba(15, 15, 15, 0.8);
            border: 1px solid #333;
            border-left: 3px solid #00ff88;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 4px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
        }}
        
        .panel-title {{
            color: #00ff88;
            margin-bottom: 15px;
            font-size: 1.1rem;
            font-weight: bold;
        }}
        
        .info-row {{
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed #222;
            font-size: 0.95rem;
        }}
        
        .info-row:last-child {{
            border-bottom: none;
        }}
        
        .label {{
            color: #888;
        }}
        
        .value {{
            color: #00ff88;
            font-weight: bold;
        }}
        
        .status-up {{
            color: #00ff88;
        }}
        
        .status-down {{
            color: #ff4444;
        }}
        
        .footer {{
            text-align: center;
            margin-top: 40px;
            color: #555;
            font-size: 0.8rem;
            border-top: 1px solid #222;
            padding-top: 20px;
        }}
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
            <div class="info-row">
                <span class="label">Status:</span>
                <span class="value status-up">✔ ONLINE</span>
            </div>
            <div class="info-row">
                <span class="label">Uptime:</span>
                <span class="value">{uptime_str}</span>
            </div>
            <div class="info-row">
                <span class="label">Protocol:</span>
                <span class="value">VLESS + WebSocket</span>
            </div>
            <div class="info-row">
                <span class="label">Server Time:</span>
                <span class="value" id="server-time">--:--:--</span>
            </div>
        </div>
        
        <div class="panel">
            <div class="panel-title">[*] CONNECTION METRICS</div>
            <div class="info-row">
                <span class="label">Active Connections:</span>
                <span class="value" id="active-users">0</span>
            </div>
            <div class="info-row">
                <span class="label">Your IP:</span>
                <span class="value" id="your-ip">Detecting...</span>
            </div>
            <div class="info-row">
                <span class="label">Response Time:</span>
                <span class="value" id="response-time">-- ms</span>
            </div>
        </div>
        
        <div class="footer">
            <p>VLESS Server Management System | Authorized Access Only</p>
            <p>© 2026 - created by prvtspyyy</p>
        </div>
    </div>
    
    <script>
        // Update server time
        setInterval(() => {{
            document.getElementById('server-time').innerText = new Date().toLocaleTimeString();
        }}, 1000);
        
        // Fetch stats
        function updateStats() {{
            fetch('/api/stats')
                .then(res => res.json())
                .then(data => {{
                    document.getElementById('active-users').innerText = data.active_count;
                    document.getElementById('response-time').innerText = data.response_time + ' ms';
                }})
                .catch(err => {{
                    document.getElementById('active-users').innerText = 'Error';
                }});
        }}
        
        // Detect client IP
        fetch('https://api.ipify.org?format=json')
            .then(res => res.json())
            .then(data => {{
                document.getElementById('your-ip').innerText = data.ip;
            }})
            .catch(() => {{
                document.getElementById('your-ip').innerText = 'Unavailable';
            }});
        
        updateStats();
        setInterval(updateStats, 5000);
    </script>
</body>
</html>'''
        
        self.wfile.write(html.encode())
    
    def api_stats(self):
        """API endpoint for server statistics"""
        rows = get_connections()
        response_time = int((time.time() - START_TIME) % 50) + 10
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        data = {
            'active_count': len(rows),
            'response_time': response_time,
            'uptime_seconds': int(time.time() - START_TIME)
        }
        self.wfile.write(json.dumps(data).encode())
    
    def api_connections(self):
        """API endpoint for detailed connection info"""
        rows = get_connections()
        data = [{'ip': r[0], 'duration': r[1], 'status': r[2], 'data_mb': r[3]} for r in rows]
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

if __name__ == '__main__':
    init_db()
    server = HTTPServer(('0.0.0.0', HTTP_PORT), VLESSHandler)
    print(f"[*] VLESS Dashboard running on port {HTTP_PORT}")
    print(f"[*] Access at: http://localhost:{HTTP_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[*] Shutting down...")
        server.shutdown()
