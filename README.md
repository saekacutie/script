# script — VLESS-WS + Status Dashboard (Cloud Run)

Cloud Run service running **Xray (VLESS)** with a small Python status dashboard.

```
:8080 ──> xray (vless inbounds, /etc/xray/config.json)
            └─ dashboard: python3 /server.py --host 127.0.0.1 --port 8081
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | `teddysun/xray` base + python3; copies entrypoint, server, helpers |
| `config.json` | Xray inbounds (vless + internal http) |
| `entrypoint.sh` | Sets `$PORT`, starts dashboard (:8081), ip-manager, xray; waits for `$PORT` |
| `server.py` | Dashboard: `/health`, `/api/stats`, `/api/connections`, `/remote_ips.txt`, `/` |
| `ip-manager.sh` / `log-user.sh` / `network-monitor.sh` | Connection/IP helpers |
| `deploy.sh` | Interactive GCP deployer (docker build → push → `gcloud run deploy`) |
| `.github/workflows/docker-build.yml` | CI: builds & pushes to GHCR on Dockerfile/config changes |

## Deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

## Dashboard endpoints (localhost :8081 inside the container)

- `GET /health` → `healthy`
- `GET /api/stats`, `GET /api/connections`
- `GET /remote_ips.txt`
