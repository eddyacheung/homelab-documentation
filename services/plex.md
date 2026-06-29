# Plex Media Server

## Overview

Plex Media Server is the central media streaming platform for the homelab. It provides access to movies and television shows managed by Sonarr and Radarr while integrating with Overseerr for media requests and qBittorrent for automated downloads.

The server is configured for an event-driven workflow where Sonarr and Radarr notify Plex immediately after successful imports. This eliminates the need for scheduled library scans and allows new media to appear within seconds.

---

## Architecture

```text
Overseerr
    |
    v
Sonarr / Radarr
    |
    v
qBittorrent
    |
    v
Download Complete
    |
    v
Import & Rename Media
    |
    v
Plex Connect Notification
    |
    v
Plex Partial Library Scan
    |
    v
Media Available to Users
```

---

## Container Configuration

| Setting | Value |
|---------|-------|
| Container Name | `plex` |
| Image | `ghcr.io/linuxserver/plex:latest` |
| Network Mode | `host` |
| Stack Manager | Portainer |
| Stack Name | `plexnew` |

## Why Host Networking?

Plex is intentionally deployed using `network_mode: host` rather than a Docker bridge network.

### Benefits

- Native DLNA support
- Reliable Chromecast discovery
- Simplified local network discovery
- No manual port mappings required
- Maximum compatibility with Plex clients

This is one of the few services in the homelab where host networking is the preferred deployment method.

---

## Library Automation

Plex does not rely on frequent full-library periodic scans. Instead, Sonarr and Radarr notify Plex when media has been successfully imported.

### Sonarr and Radarr Connect Settings

| Setting | Value |
|---------|-------|
| Host | `172.26.0.1` |
| Port | `32400` |
| SSL | Disabled |
| Authentication | Plex OAuth |

### Enabled Events

- On File Import
- On File Upgrade
- On Import Complete

Optional:

- On Rename

This allows newly imported media to appear in Plex within seconds after Sonarr or Radarr finishes importing and renaming the file.

---

## Plex Library Settings

### Enabled

- Scan my library automatically
- Run a partial scan when changes are detected
- Empty trash automatically after every scan
- Allow media deletion

### Disabled

- Scan my library periodically

Using Sonarr and Radarr notifications is more efficient than scheduled periodic scans because Plex only refreshes when the media stack changes.

---

## Docker Host Gateway

Containers on `media-net` should access Plex using the Docker bridge gateway instead of the NAS LAN address.

### Correct

```text
http://172.26.0.1:32400
```

### Avoid

```text
http://192.168.10.101:32400
```

Although the LAN address is reachable from the NAS itself, containers on `media-net` could not reliably communicate with Plex using the NAS LAN IP. The Docker bridge gateway provides a reliable path from containers to host-networked services.

---

## Verification Commands

Check that Plex is running:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -i plex
```

Expected result:

```text
plex    ghcr.io/linuxserver/plex:latest    Up ... (healthy)
```

Check Plex from the NAS host:

```bash
curl http://127.0.0.1:32400/identity
```

Check Plex from Sonarr over the Docker bridge gateway:

```bash
docker exec sonarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

Both commands should return Plex XML containing the server version and machine identifier.

---

## Network Cleanup Notes

During Plex troubleshooting, unused Docker bridge networks were audited and removed with `docker network prune`.

Before pruning, active container counts were checked with:

```bash
docker network inspect $(docker network ls -q) --format '{{.Name}}: {{len .Containers}} containers'
```

Unused service-specific default networks were removed. Active networks were left in place.

Current important networks include:

- `media-net`
- `ai-net`
- `pihole_macvlan`
- `host`
- `bridge`
- `none`

---

## Container Rename Notes

The Plex container was renamed from `PlexHW` to `plex` for consistency with the rest of the homelab container naming convention.

The Portainer stack definition was updated so the rename survives future stack redeployments.

---

## Lessons Learned

- Host-networked services are best accessed from Docker containers through the Docker bridge gateway (`172.26.0.1`).
- Event-driven Plex updates are preferred over scheduled periodic library scans.
- Standardized lowercase container names make Docker commands and documentation easier to maintain.
- Plex should remain on `network_mode: host` for best compatibility with local discovery protocols and Plex clients.

---

## Related Services

- Sonarr
- Radarr
- Overseerr
- qBittorrent
- Prowlarr
- Nginx Proxy Manager
- Docker Networking
