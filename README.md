# Debian 12 VPN front-end, certificate testing, and management stack

This repo contains a Debian 12 automation setup for a VPN front-end and modern management system with:

- Nginx TLS front-end and custom response modes
- HTTP 101 CHKDARKMASTER behavior when the client sends an upgrade header
- HTTP/1.1-only CHKDARKMASTER handshake matching
- Automatic local-midnight restart timer for the VPN frontend services
- SSH banner customization for three styles (1, 2, 3)
- WireGuard on UDP 51820
- OpenVPN on UDP 1194
- IPsec / strongSwan on UDP 500 and 4500
- UFW firewall rules for the required ports
- Domain-based TLS handshake verification using OpenSSL
- Optional badvpn UDPGW service for authorized SSH tunnel clients on TCP 7300
- DNS ownership/IP validation before automatic Let's Encrypt issuance
- A responsive operations console for service, session, and security status
- Authenticated administrator accounts with password rotation and allowlisted service controls
- Individual WireGuard client profiles with expiry, handshake status, secure download, and revocation
- Periodic status reporting with aggregate protocol activity

## Included files

- `setup-vpn-stack.sh` — full VPS bootstrap installer
- `vpn-admin.sh` — management console for service and protocol checks
- `vpn-status.py` — JSON status collector for the admin panel
- `admin-api.py` — loopback-only authenticated admin and WireGuard client API
- `cert-check.sh` — certificate and TLS handshake test
- `verify-vpn-stack.sh` — repository and live-VPS configuration audit
- `web-panel/` — responsive VPS operations console

## Quick start

Run as root on a Debian 12 VPS:

```bash
sudo bash ./setup-vpn-stack.sh --domain vpn.example.com --email admin@example.com --ssh-banner-mode 1
```

On first install, the setup prompts for an initial password without echoing it. The initial admin username defaults to `saeka`; the first sign-in requires changing the temporary password to one with at least 14 characters. For automated installs, provide `VPN_ADMIN_USERNAME` and `VPN_ADMIN_PASSWORD` through a secrets manager. Do not commit the password or place it directly in a command line.

The installer names the public ports explicitly: SSH `22/tcp`, HTTP `80/tcp`, HTTPS `443/tcp`, WireGuard `51820/udp`, OpenVPN `1194/udp`, IPsec `500/udp` and `4500/udp`, and optional UDPGW `7300/tcp`.

Optional dry run:

```bash
sudo bash ./setup-vpn-stack.sh --domain vpn.example.com --email admin@example.com --ssh-banner-mode 3 --dry-run
```

## Management

```bash
sudo bash ./vpn-admin.sh
```

Or on the live VPS after install:

```bash
/usr/local/bin/vpn-admin
```

The client portal is served at the HTTPS domain root (`https://vpn.example.com/`); users sign in with the username and temporary password generated when an administrator creates their account. First sign-in requires a password change. Users can inspect live WireGuard status and traffic, change their password, and download their profile. The SAEKA admin console remains at `/admin/`. Use its **Admin users** view to manage console administrators and **VPN accounts** to create, reset, inspect, download, or revoke client access. The downloaded `.conf` contains the client's private key and must be delivered securely. Service restarts are limited to installer-managed units and require confirmation.

## Certificate test

```bash
/usr/local/bin/vpn-cert-check vpn.example.com 443
```

or:

```bash
bash ./cert-check.sh vpn.example.com 443
```

Run the audit after installation:

```bash
sudo bash ./verify-vpn-stack.sh
```

## Notes

- The installer creates a temporary self-signed certificate, validates that the domain resolves to the VPS, and then requests a Let's Encrypt certificate automatically.
- ACME requires DNS to point to this VPS and inbound TCP `80` to be reachable. If those checks fail, installation continues with the temporary certificate and reports the reason.
- The setup intentionally does not impersonate unrelated third-party domains or implement domain-fronting. TLS/SNI is matched only to the domain you control.
- No VPN can truthfully guarantee `100%` anti-DPI behavior. Detection depends on the network, protocol fingerprints, traffic volume, and client behavior. This project uses standard TLS 1.2/1.3, explicit SNI for your own domain, firewall minimization, and certificate verification rather than stealth or domain impersonation.
- The client portal is served at `/`; the administrator console is served separately at `/admin/`.
- Nginx is configured to handle a custom `CHKDARKMASTER` styled response and proxies authenticated `/api/` requests to the loopback-only admin API.
- The portal reads live peer status and transfer counters every five seconds; aggregate service telemetry is refreshed by `vpn-status-refresh.timer` every 30 seconds.
- The `/` handshake still returns `101` only when both the request protocol is HTTP/1.1 and `Upgrade: CHKDARKMASTER` is present. Normal browser requests to `/` receive the client portal. The HTTPS listener intentionally does not advertise HTTP/2 for the handshake endpoint.
- `vpnfront-restart.timer` restarts the VPN frontend services at `00:00:00` in the VPS local timezone. Existing VPN sessions will be interrupted and clients must reconnect.

## Security and status

- UFW is enabled with required inbound ports allowed.
- SSH banner customization is applied to `/etc/ssh/banner` and the motd hook.
- Aggregate JSON status data is generated for the admin panel and can be inspected in `/var/lib/vpnfront/status.json`. Client identifiers and endpoint details are not included.
- Admin passwords are salted PBKDF2 hashes in `/var/lib/vpnfront/admin.sqlite3`; sessions use secure, HTTP-only cookies and CSRF tokens. The API is not exposed on a public interface.
- Client portal passwords are separately salted PBKDF2 hashes and use their own secure session cookie and CSRF token. Temporary passwords are shown once when the admin creates or resets a user login.
- WireGuard client keys and expiry metadata are stored in the root-only admin database; expired peers are removed from the live interface and persisted config. Client profiles currently support WireGuard only; OpenVPN and IPsec are not configured for individual account credentials.
- WireGuard client traffic is forwarded and NATed through the VPS default IPv4 interface. IPv6 full-tunnel routing is not advertised because this installer does not configure an IPv6 VPN subnet.
- UDPGW is optional because Debian repositories may not ship the `badvpn-udpgw` binary. The service is configured only when that trusted binary is already available; use `--disable-udpgw` to skip its firewall rule too.
