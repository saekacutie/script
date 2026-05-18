# VLESS WebSocket TLS - Google Cloud Run

Automated VLESS deployment with Xray on Google Cloud Run.

## Features

✅ **VLESS Protocol** - Ultra-fast, zero-copy tunneling  
✅ **WebSocket Transport** - ws:// over TLS  
✅ **Decoy Routing** - Masquerade with custom headers  
✅ **Cloud Run Ready** - Auto-scaling, fully managed  
✅ **Live Dashboard** - Connection monitoring  
✅ **Health Checks** - Built-in monitoring  

## Quick Start

### Prerequisites

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

## Configuration

Edit `config.json` to customize:

- **UUID** - Your connection identifier
- **WS Path** - WebSocket endpoint (default: `/prvtspyyy`)
- **Host Header** - Decoy domain for masquerading

## Access Points

- **Main Service** - Cloud Run domain (HTTPS port 443)
- **Dashboard** - `https://SERVICE.run.app/`
- **Health Check** - `https://SERVICE.run.app/health`
- **Stats API** - `https://SERVICE.run.app/api/stats`

## VLESS URI Format

```
vless://UUID@host:443?encryption=none&security=tls&type=ws&path=/prvtspyyy&host=domain&sni=domain&fp=chrome
```

## Client Configuration

### On v2rayN / v2rayNG

1. Import VLESS URI from deployment output
2. Set TLS to "tls"
3. Set WebSocket path to `/prvtspyyy`
4. Leave encryption as "none"

### On Xray / Clash

```yaml
proxies:
  - name: VLESS-WS-TLS
    type: vless
    server: cloud-run-domain.run.app
    port: 443
    uuid: YOUR_UUID
    tls: true
    ws-opts:
      path: /prvtspyyy
    alpn:
      - h2
      - http/1.1
```

## Architecture

```
Client (VLESS)
    ↓ (TLS + WebSocket)
Cloud Run Service (Port 8080)
    ├→ /prvtspyyy → Xray VLESS Protocol → Freedom Outbound
    ├→ /api/* → Dashboard Server (Port 8081)
    └→ /health → Health Check Response
```

## Troubleshooting

**Build Failed**
- Enable Cloud Build API
- Check Dockerfile syntax

**Connection Failed**
- Verify UUID in config.json
- Check Cloud Run logs: `gcloud run services logs`
- Test health check: `curl https://SERVICE.run.app/health`

**High Latency**
- Select region closer to you
- Increase CPU/Memory allocation

## Security Notes

⚠️ **Important**: 
- This is for educational purposes only
- Change default UUID to a secure one
- Monitor Cloud Run logs regularly
- Comply with local laws and regulations

## License

MIT - created by prvtspyyy
