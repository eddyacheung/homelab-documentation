# Gluetun + NordVPN

## Purpose

Gluetun provides a VPN gateway for qBittorrent using NordVPN over OpenVPN.

The goal is to route only torrent traffic through the VPN while leaving the rest of the media stack on the normal LAN / WAN path.

Benefits:

- Network-level VPN routing for qBittorrent
- Kill switch behavior when the VPN is unavailable
- DNS leak protection through Gluetun
- No SOCKS5 proxy dependency inside qBittorrent
- Minimal impact on Plex, Sonarr, Radarr, Prowlarr, Seerr, and other services

---

## Architecture

```text
qBittorrent
    |
    v
Gluetun
    |
    v
NordVPN OpenVPN tunnel
    |
    v
Internet
```

qBittorrent shares Gluetun's network namespace:

```yaml
network_mode: "service:gluetun"
```

This means qBittorrent does not have its own independent Docker network path. If Gluetun is stopped or the VPN tunnel is unavailable, qBittorrent loses internet connectivity instead of falling back to the NAS WAN connection.

---

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Portainer stack:** `compose/38`
- **Compose file:** `/volume1/docker/portainer/compose/38/docker-compose.yml`
- **VPN container:** `gluetun`
- **Protected application:** `qbittorrent`
- **VPN provider:** NordVPN
- **VPN protocol:** OpenVPN
- **Docker network:** `media-net`

---

## Environment File

OpenVPN credentials are stored outside the Compose file:

```text
/volume1/docker/qbittorrent/.env
```

Expected variable names:

```text
OPENVPN_USER
OPENVPN_PASSWORD
```

The `.env` file should remain protected:

```bash
chmod 600 /volume1/docker/qbittorrent/.env
```

Do not commit VPN credentials to Git.

---

## Firewall

Gluetun firewall is enabled:

```text
FIREWALL=on
```

Allowed inbound ports:

```text
FIREWALL_INPUT_PORTS=8888,6888
```

Ports:

| Port | Purpose |
| --- | --- |
| `8888/tcp` | qBittorrent WebUI |
| `6888/tcp` | Torrent listening port |
| `6888/udp` | Torrent listening port |

The qBittorrent WebUI is published through the Gluetun container because qBittorrent shares Gluetun's network namespace.

---

## Access

qBittorrent WebUI:

```text
http://NAS-IP:8888
```

Example:

```text
http://192.168.10.101:8888
```

---

## Validation

Check container status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "gluetun|qbittorrent"
```

Expected:

```text
gluetun       Up ... (healthy)
qbittorrent   Up ...
```

Check Gluetun logs:

```bash
docker logs gluetun --tail=80
```

Successful VPN connection includes:

```text
Initialization Sequence Completed
Public IP address is ...
```

Check qBittorrent WebUI from the NAS:

```bash
curl -I http://127.0.0.1:8888
```

Expected:

```text
HTTP/1.1 200 OK
```

Check qBittorrent public IP:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

Expected result:

- Public IP should be a NordVPN endpoint
- Public IP should not be the home WAN IP

---

## Kill Switch Test

Stop Gluetun:

```bash
docker stop gluetun
```

Test qBittorrent internet access:

```bash
docker exec qbittorrent curl -m 10 -s https://ipinfo.io/ip || echo "No internet from qbittorrent"
```

Expected result:

```text
No internet from qbittorrent
```

Restart the stack:

```bash
cd /volume1/docker/portainer/compose/38
docker compose up -d
```

Re-check VPN IP:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

---

## qBittorrent SOCKS5 Proxy

The old qBittorrent SOCKS5 proxy configuration was removed.

Reason:

- qBittorrent now routes through Gluetun at the network layer.
- SOCKS5 inside qBittorrent is redundant.
- Leaving SOCKS5 enabled can slow tracker communication or make troubleshooting harder.

Current desired qBittorrent proxy setting:

```text
Proxy Server Type: None
```

---

## WireGuard / NordLynx Notes

NordVPN WireGuard / NordLynx was considered first.

OpenVPN was selected because NordVPN's manual setup portal did not expose a straightforward WireGuard private key or access token workflow during implementation.

Future improvement:

- Convert Gluetun from OpenVPN to WireGuard if NordVPN credentials become easy to provision.
- The overall architecture can remain the same.
- Only Gluetun VPN environment variables should need to change.

---

## Recovery / Rollback

A backup of the previous qBittorrent Compose file was created before migration:

```text
/volume1/docker/qbittorrent/backups/
```

To roll back:

1. Stop the current stack.
2. Restore the backed-up qBittorrent Compose file.
3. Redeploy the stack.
4. Re-enable the old qBittorrent proxy only if returning to the old SOCKS5 design.

Example:

```bash
cd /volume1/docker/portainer/compose/38
docker compose down

cp /volume1/docker/qbittorrent/backups/<backup-file> \
  /volume1/docker/portainer/compose/38/docker-compose.yml

docker compose up -d
```

---

## Lessons Learned

- Gluetun and qBittorrent should live in the same Compose stack when using `network_mode: service:gluetun`.
- The qBittorrent container can be safely recreated when config and downloads are bind-mounted.
- Gluetun's firewall must explicitly allow qBittorrent WebUI access with `FIREWALL_INPUT_PORTS`.
- The WebUI can work inside the shared namespace while still being blocked from the LAN by Gluetun's firewall.
- OpenVPN credentials must use Gluetun's expected variable names: `OPENVPN_USER` and `OPENVPN_PASSWORD`.
- The kill switch should be tested directly after deployment, not assumed.
