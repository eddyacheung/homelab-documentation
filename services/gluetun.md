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
network_mode: service:gluetun
```

This means qBittorrent does not have its own independent Docker network path. If Gluetun is stopped or the VPN tunnel is unavailable, qBittorrent loses internet connectivity instead of falling back to the NAS WAN connection.

---

## Deployment

| Setting | Value |
| --- | --- |
| Host | UGREEN DXP4800 Plus |
| Portainer stack | `qbittorrent` |
| VPN container | `gluetun` |
| Protected application | `qbittorrent` |
| VPN provider | NordVPN |
| VPN protocol | OpenVPN |
| Docker network | `media-net` |

The old anonymous / numeric stack was replaced on 2026-07-08. Current state:

```text
Stack:       qbittorrent
Project:     qbittorrent
Containers:  gluetun, qbittorrent
```

---

## Important Network Pattern

Gluetun attaches to `media-net`:

```yaml
services:
  gluetun:
    networks:
      - media-net
```

qBittorrent does not attach directly to `media-net`. It shares Gluetun's network namespace:

```yaml
services:
  qbittorrent:
    network_mode: service:gluetun
```

This is intentional.

Reason:

- Gluetun is the reachable network endpoint.
- qBittorrent is forced through the VPN gateway.
- Radarr, Sonarr, and Prowlarr can reach qBittorrent through `gluetun:8888` on `media-net`.

---

## Environment Variables

OpenVPN credentials must use Gluetun's expected variable names:

```yaml
OPENVPN_USER: <nordvpn-service-username>
OPENVPN_PASSWORD: <nordvpn-service-password>
```

Do not use normal Nord account login credentials. Use NordVPN service / manual setup credentials.

Important YAML note:

```yaml
OPENVPN_USER: value
OPENVPN_PASSWORD: value
```

Do not write these as `OPENVPN_USER=value` inside a YAML mapping. That malformed syntax caused Gluetun to receive bad or missing credentials and resulted in OpenVPN `AUTH_FAILED` errors.

Do not commit real VPN credentials to Git.

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

qBittorrent WebUI from the LAN:

```text
http://NAS-IP:8888
```

Example:

```text
http://192.168.10.101:8888
```

Internal Docker service access from Radarr, Sonarr, and Prowlarr:

```text
Host: gluetun
Port: 8888
```

Do not use `qbittorrent` as the host from other containers. qBittorrent does not have its own Docker network endpoint when it uses `network_mode: service:gluetun`.

---

## Radarr / Sonarr / Prowlarr Download Client

Use:

```text
Host: gluetun
Port: 8888
Use SSL: unchecked
```

Avoid:

```text
Host: qbittorrent
Port: 8888
```

Also avoid using the NAS IP from inside the media stack unless troubleshooting. The preferred internal path is Docker DNS over `media-net`:

```text
radarr / sonarr / prowlarr -> gluetun:8888 -> qbittorrent
```

---

## Validation

Check container status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}" | grep -E "gluetun|qbittorrent"
```

Expected:

```text
gluetun       Up ... (healthy)   qbittorrent
qbittorrent   Up ...             qbittorrent
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

Check qBittorrent public IP:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

Expected result:

- Public IP should be a NordVPN endpoint
- Public IP should not be the home WAN IP

Confirm Gluetun is attached to `media-net`:

```bash
docker inspect gluetun --format '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}'
```

Expected:

```text
media-net
```

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

Restart the stack from Portainer, or from the host-side Compose directory if needed:

```bash
cd /volume1/docker/qbittorrent
docker compose up -d
```

---

## qBittorrent SOCKS5 Proxy

The old qBittorrent SOCKS5 proxy configuration should remain disabled.

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

## 2026-07-08 Cleanup Notes

The previous qBittorrent/Gluetun deployment appeared in Portainer as an external stack named `38`. Its Compose folder was missing, so the stack could not be cleanly edited.

Cleanup performed:

1. Backed up running container details with `docker inspect`.
2. Reconstructed the Compose file.
3. Recreated the stack as `qbittorrent`.
4. Attached Gluetun to `media-net`.
5. Kept qBittorrent behind Gluetun with `network_mode: service:gluetun`.
6. Restored Radarr, Sonarr, and Prowlarr download client settings to `gluetun:8888`.
7. Redeployed through Portainer so the Editor tab is available.

---

## Recovery / Rollback

Backups were created before migration using Docker inspect output and Compose file copies.

To recover from a broken deployment:

1. Stop the `qbittorrent` stack in Portainer.
2. Restore the last known good Compose configuration.
3. Confirm OpenVPN credentials are valid and use YAML mapping syntax.
4. Redeploy the stack.
5. Verify Gluetun logs include `Initialization Sequence Completed`.
6. Test Radarr, Sonarr, and Prowlarr download client connectivity.

Host-side fallback:

```bash
cd /volume1/docker/qbittorrent
docker compose up -d
```

---

## Lessons Learned

- Gluetun and qBittorrent should live in the same Compose stack when using `network_mode: service:gluetun`.
- Gluetun should attach to `media-net`; qBittorrent should not attach directly.
- Radarr, Sonarr, and Prowlarr should use `gluetun:8888` to reach qBittorrent.
- OpenVPN credentials must use valid YAML key/value syntax.
- Gluetun's firewall must explicitly allow qBittorrent WebUI access with `FIREWALL_INPUT_PORTS`.
- The kill switch should be tested directly after deployment, not assumed.
