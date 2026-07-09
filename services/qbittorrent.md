# qBittorrent

## Purpose

qBittorrent is the torrent download client used by Radarr, Sonarr, and Prowlarr.

It is intentionally routed through Gluetun so torrent traffic exits through NordVPN instead of the normal home WAN connection.

---

## Deployment

| Setting | Value |
| --- | --- |
| Host | UGREEN DXP4800 Plus |
| Stack name | `qbittorrent` |
| Container name | `qbittorrent` |
| Image | `lscr.io/linuxserver/qbittorrent:latest` |
| Stack manager | Portainer |
| VPN gateway | `gluetun` |
| WebUI port | `8888` |
| Torrent port | `6888/tcp` and `6888/udp` |
| Config path | `/volume1/docker/qbittorrent/config:/config` |
| Media path | `/volume2/Media:/data` |

The qBittorrent and Gluetun containers are deployed together in the same Portainer stack named `qbittorrent`.

---

## Network Model

qBittorrent uses Gluetun's network namespace:

```yaml
network_mode: service:gluetun
```

This means qBittorrent does not have its own independent Docker network endpoint. Gluetun owns the network path, firewall rules, published ports, and VPN tunnel.

Traffic flow:

```text
Radarr / Sonarr / Prowlarr
    |
    v
media-net
    |
    v
gluetun:8888
    |
    v
qBittorrent WebUI
```

Outbound torrent traffic:

```text
qBittorrent
    |
    v
Gluetun
    |
    v
NordVPN OpenVPN
    |
    v
Internet
```

---

## Ports

Ports are published on the Gluetun container, not directly on qBittorrent.

| Port | Protocol | Purpose |
| --- | --- | --- |
| `8888` | TCP | qBittorrent WebUI |
| `6888` | TCP | Torrent listening port |
| `6888` | UDP | Torrent listening port |

Gluetun must allow these ports through its firewall:

```text
FIREWALL_INPUT_PORTS=8888,6888
```

---

## Radarr / Sonarr / Prowlarr Settings

Use this download client endpoint:

```text
Host: gluetun
Port: 8888
Use SSL: unchecked
```

Do not use:

```text
Host: qbittorrent
```

Reason: qBittorrent is not attached to `media-net` as its own network identity when using `network_mode: service:gluetun`.

The NAS IP can work as a fallback, but the preferred internal Docker path is `gluetun:8888`.

---

## Volumes

Current bind mounts:

```yaml
volumes:
  - /volume1/docker/qbittorrent/config:/config
  - /volume2/Media:/data
```

The `/config` path stores qBittorrent application settings.

The `/data` path maps to the shared media volume used by the media automation stack.

---

## Environment

Important qBittorrent settings:

```yaml
TZ: America/Chicago
WEBUI_PORT: "8888"
PUID: "1001"
PGID: "10"
```

---

## 2026-07-08 Stack Cleanup

Previous state:

```text
Project / stack: 38
Containers:      gluetun, qbittorrent
Portainer:       limited / external stack
```

Problem:

- Portainer showed a numeric stack named `38`.
- The original Compose folder for stack `38` was missing.
- A stale empty `qbittorrent` stack record also existed.
- The deployment was functional but not cleanly editable or self-documenting.

Cleanup performed:

1. Deleted the empty orphaned `qbittorrent` stack record.
2. Backed up the running qBittorrent and Gluetun container definitions with `docker inspect`.
3. Reconstructed a clean Compose file.
4. Recreated the stack as `qbittorrent`.
5. Reattached Gluetun to `media-net`.
6. Kept qBittorrent behind Gluetun with `network_mode: service:gluetun`.
7. Verified Gluetun reached a healthy VPN state.
8. Verified Radarr, Sonarr, and Prowlarr all passed their qBittorrent connection tests.
9. Redeployed the stack through Portainer so the Editor tab is available.

Current state:

```text
Project / stack: qbittorrent
Containers:      gluetun, qbittorrent
Portainer:       managed stack with Editor tab
```

---

## Validation Commands

Check container status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}" | grep -E "qbittorrent|gluetun"
```

Expected:

```text
qbittorrent   Up ...             qbittorrent
gluetun       Up ... (healthy)   qbittorrent
```

Check qBittorrent WebUI from the NAS:

```bash
curl -I http://127.0.0.1:8888
```

Check Gluetun logs:

```bash
docker logs --tail=80 gluetun
```

Expected successful VPN line:

```text
Initialization Sequence Completed
```

Check Gluetun network membership:

```bash
docker inspect gluetun --format '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}'
```

Expected:

```text
media-net
```

Test from Radarr / Sonarr / Prowlarr UI:

```text
Download Client Host: gluetun
Download Client Port: 8888
```

---

## Recovery

If qBittorrent becomes unreachable:

1. Check Gluetun health first.
2. Check Gluetun logs for VPN or credential errors.
3. Confirm Gluetun is attached to `media-net`.
4. Confirm Radarr/Sonarr/Prowlarr are using `gluetun:8888`.
5. Confirm qBittorrent is still using `network_mode: service:gluetun`.

Useful commands:

```bash
docker logs --tail=80 gluetun
docker inspect qbittorrent --format '{{.HostConfig.NetworkMode}}'
docker inspect gluetun --format '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}'
```

Host-side fallback redeploy:

```bash
cd /volume1/docker/qbittorrent
docker compose up -d
```

Preferred management path is the Portainer stack named `qbittorrent`.

---

## Lessons Learned

- The qBittorrent container should not be expected to resolve as `qbittorrent` from other containers when it shares Gluetun's network namespace.
- Gluetun is the network endpoint for qBittorrent.
- Use `gluetun:8888` for Radarr, Sonarr, and Prowlarr.
- Keep Gluetun on `media-net` so media services can reach it by Docker DNS.
- Avoid anonymous or numeric Portainer stacks when a service has long-term value.
- Back up working container state before stack migrations.
