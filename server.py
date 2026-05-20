#!/usr/bin/env python3
import sqlite3, json, os, time, argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from datetime import datetime
import threading

DB_FILE = "/tmp/vless_users.db"
IP_FILE = "/tmp/remote_ips.txt"
START_TIME = time.time()

def init_db():
    with sqlite3.connect(DB_FILE) as c:
        c.execute('''CREATE TABLE IF NOT EXISTS connections (
            id INTEGER PRIMARY KEY AUTOINCREMENT, source_ip TEXT UNIQUE,
            connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            duration TEXT DEFAULT '00:00:00', status TEXT DEFAULT 'ACTIVE'
        )''')

def update_ip_file():
    while True:
        try:
            with sqlite3.connect(DB_FILE) as c:
                ips = [r[0] for r in c.execute("SELECT source_ip FROM connections WHERE status='ACTIVE' ORDER BY last_seen DESC").fetchall()]
            with open(IP_FILE, 'w') as f:
                f.write(f"# Updated: {datetime.now()}\n# Total: {len(ips)}\n\n" + "\n".join(ips))
        except: pass
        time.sleep(10)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path)
        if p.path == '/health':
            self.send(200, 'text/plain', b'healthy')
        elif p.path == '/remote_ips.txt':
            self.serve_file()
        elif p.path == '/api/stats':
            self.serve_stats()
        elif p.path == '/api/connections':
            self.serve_conns()
        elif p.path == '/':
            self.serve_dash()
        else:
            self.send(404, 'text/plain', b'Not Found')

    def send(self, code, ctype, data):
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.end_headers()
        self.wfile.write(data)

    def serve_file(self):
        if os.path.exists(IP_FILE):
            self.send(200, 'text/plain', open(IP_FILE,'rb').read())
        else: self.send(404,'text/plain',b'No file')

    def serve_stats(self):
        uptime = int(time.time()-START_TIME)
        with sqlite3.connect(DB_FILE) as c:
            active = c.execute("SELECT COUNT(*) FROM connections WHERE status='ACTIVE'").fetchone()[0]
        data = json.dumps({'active':active,'uptime':uptime})
        self.send(200,'application/json',data.encode())

    def serve_conns(self):
        with sqlite3.connect(DB_FILE) as c:
            res = c.execute("SELECT * FROM connections").fetchall()
        self.send(200,'application/json',json.dumps(res).encode())

    def serve_dash(self):
        html = f'''<!DOCTYPE html><html><head><meta charset=utf-8><title>VLESS+XHTTP</title>
<style>body{{background:#0a0e27;color:#e0e0e0;font-family:monospace;padding:20px}}
.box{{background:#111;border-left:3px solid #0f8;padding:15px;margin:10px 0}}</style></head>
<body><h1 style="color:#0f8">⚡ VLESS Manager</h1>
<div class=box><b>Status:</b> ONLINE<br><b>Protocol:</b> VLESS+XHTTP<br><b>Uptime:</b> {int(time.time()-START_TIME)}s<br>
<b>IP List:</b> <a href=/remote_ips.txt style="color:#0f8">/remote_ips.txt</a></div></body></html>'''
        self.send(200,'text/html',html.encode())

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--host',default='127.0.0.1')
    ap.add_argument('--port',type=int,default=8081)
    a = ap.parse_args()
    init_db()
    threading.Thread(target=update_ip_file,daemon=True).start()
    HTTPServer((a.host,a.port),Handler).serve_forever()
