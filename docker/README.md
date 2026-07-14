# Docker Stack Index

This directory is the version-controlled source for Docker Compose definitions used by the homelab.

The live services are deployed primarily through Portainer, but changes should begin here so they can be reviewed, committed, and rolled back before deployment.

## Workflow

1. Edit the stack's `docker-compose.yml` in Git.
2. Update `.env.example` when required variables change.
3. Run the repository validation checks.
4. Commit and push the change.
5. Apply the same Compose definition in Portainer.
6. Verify the live service and update its service documentation when behavior changes.

Real `.env` files and secrets must never be committed.

## Stack Inventory

| Stack | Purpose | Primary access | Network | Detailed documentation |
| --- | --- | --- | --- | --- |
| [cloudflared](cloudflared/) | Cloudflare Tunnel connector | No local UI | `media-net` | [Cloudflare Zero Trust](../networking/cloudflare-zero-trust.md) |
| [eufy-security-ws](eufy-security-ws/) | Eufy websocket backend for Home Assistant | `127.0.0.1:3000` | Default bridge with loopback-only published port | [Eufy camera integration](../services/home-assistant-eufy-cameras.md) |
| [go2rtc](go2rtc/) | Low-latency camera stream relay | Host-local services | Host | [Eufy camera integration](../services/home-assistant-eufy-cameras.md) |
| [homebridge](homebridge/) | Apple Home bridge | `http://NAS-IP:8581` | Host | [Homebridge stack](homebridge/README.md) |
| [nginx-proxy-manager](nginx-proxy-manager/) | Reverse proxy and certificates | `http://NAS-IP:8181` | `media-net` | [Nginx Proxy Manager](../services/nginx-proxy-manager.md) |
| [open-webui](open-webui/) | Local AI chat interface | `http://NAS-IP:3002` | `ai-net` | [Open WebUI](../services/open-webui.md) |
| [pihole](pihole/) | Network DNS filtering | `http://192.168.10.250/admin` | `pihole_macvlan` | [Pi-hole](../networking/pihole.md) |
| [plex](plex/) | Media server | `http://NAS-IP:32400/web` | Host | [Plex](../services/plex.md) |
| [portainer](portainer/) | Docker management UI | `http://NAS-IP:9000` | `portainer_default`, `media-net` | [Portainer](../services/portainer.md) |
| [prowlarr](prowlarr/) | Indexer management | `http://NAS-IP:9696` | `media-net` | [Prowlarr stack](prowlarr/README.md) |
| [qbittorrent](qbittorrent/) | VPN-isolated download client | `http://NAS-IP:8888` | `media-net` through Gluetun | [qBittorrent](../services/qbittorrent.md) |
| [radarr](radarr/) | Movie automation | `http://NAS-IP:7878` | `media-net` | [Radarr stack](radarr/README.md) |
| [recyclarr](recyclarr/) | TRaSH profile synchronization | No UI | `media-net` | [Recyclarr](../services/recyclarr.md) |
| [seerr](seerr/) | Media request management | `http://NAS-IP:5055` | `media-net` | [Seerr stack](seerr/README.md) |
| [sonarr](sonarr/) | TV automation | `http://NAS-IP:8989` | `media-net` | [Sonarr stack](sonarr/README.md) |
| [unbound](unbound/) | Recursive DNS resolver | Internal DNS | `media-net` | [Unbound](../networking/unbound.md) |
| [unpackerr](unpackerr/) | Archive extraction for Radarr and Sonarr | No UI | `media-net` | [Unpackerr stack](unpackerr/README.md) |
| [uptime-kuma](uptime-kuma/) | Availability monitoring | `http://NAS-IP:3001` | `media-net` | [Uptime Kuma](../services/uptime-kuma.md) |
| [watchtower](watchtower/) | Label-based image updates | No normal UI | Docker socket | [Watchtower](../services/watchtower.md) |

## Directory Contract

Each stack directory should contain:

```text
stack-name/
├── docker-compose.yml
├── README.md
└── .env.example      # only when variables or secrets are required
```

The stack README should describe purpose, dependencies, networks, storage, required variables, deployment, verification, and recovery considerations.
