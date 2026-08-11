# Plex Media Server

## Overview

Plex Media Server is the central media streaming platform for the homelab. It provides access to movies and television shows managed by Sonarr and Radarr while integrating with Seerr for media requests and qBittorrent for automated downloads.

The server is configured for an event-driven workflow where Sonarr and Radarr notify Plex immediately after successful imports. This eliminates the need for scheduled library scans and allows new media to appear within seconds.

---

## Architecture

```text
Seerr
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
    |
    v
Tautulli monitoring / history
```

---

## Container Configuration

| Setting | Value |
|---------|-------|
| Container Name | `plex` |
| Image | `ghcr.io/linuxserver/plex:latest` |
| Network Mode | `host` |
| Stack Manager | Portainer |
| Stack Name | `plex` |
| Config Volume | `/volume1/docker/plexhw:/config` |
| Media Mount | `/volume2/Media:/media:ro` |
| Transcode Mount | `/volume1/docker/plexhw/transcode:/transcode` |

The Plex stack was renamed from `plexnew` to `plex` on 2026-07-08. The container name was already `plex`; only the Portainer stack / Compose project name needed cleanup.

---

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

## Docker Host Access

Containers cannot reliably use the NAS LAN address `192.168.10.101:32400` to reach the host-networked Plex service on this NAS.

Existing Sonarr/Radarr integrations use the reachable Docker bridge gateway:

```text
http://172.26.0.1:32400
```

For newly documented stacks where the Compose definition can be controlled, prefer Docker's stable host alias:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Then connect to Plex with:

```text
http://host.docker.internal:32400
```

Tautulli uses this method. It avoids pinning the service to a Docker `172.x` gateway that may change if networks are recreated.

### Avoid

```text
http://192.168.10.101:32400
```

A container-level test against the NAS LAN address timed out even though the address worked from other contexts.

---

## Tautulli Integration

Tautulli is deployed on `media-net` and monitors Plex through:

```text
host.docker.internal:32400
```

The connection was validated from inside the Tautulli container:

```bash
docker exec tautulli curl -v --connect-timeout 5 http://host.docker.internal:32400/identity
```

Expected response:

```text
HTTP/1.1 200 OK
```

Tautulli successfully records live playback, Direct Play/transcode state, codecs, bandwidth, users, libraries, recently added media, and historical watch statistics.

---

## LAN Networks

Plex `LAN Networks` is explicitly configured as:

```text
192.168.10.0/24,192.168.2.0/24
```

The second subnet was added after an Apple TV at `192.168.2.218` appeared as WAN in Tautulli. Restarting playback after the change caused the stream to be reported correctly as LAN.

This setting is separate from **List of IP addresses and networks that are allowed without auth**. Do not expand unauthenticated access merely to correct LAN/WAN classification.

---

## Verification Commands

Check that Plex is running:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}" | grep -i plex
```

Expected result:

```text
plex    ghcr.io/linuxserver/plex:latest    Up ... (healthy)    plex
```

Check Plex from the NAS host:

```bash
curl http://127.0.0.1:32400/identity
```

Check Plex from Sonarr over the Docker bridge gateway:

```bash
docker exec sonarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

Check Plex from Tautulli over the stable Docker host alias:

```bash
docker exec tautulli curl --connect-timeout 5 http://host.docker.internal:32400/identity
```

These commands should return Plex XML containing the server version and machine identifier.

---

## Media Directory Permission Troubleshooting

### Symptoms

- Playback failed in both Plex and Infuse.
- Plex logged `boost::filesystem::status: Permission denied` while checking media files.
- Media files existed and could be listed from the NAS host.
- A root-level `docker exec` test could read the files, which initially hid the real service-account permission problem.

### Root Cause

Plex runs as UID `1001` and GID `10` (`admin`). The top-level media directory was owned by `root:root` with mode `770`, so Plex could not traverse `/volume2/Media` even though files and child directories were readable.

Problem state:

```text
drwxrwx--- root root /volume2/Media
```

### Resolution

```bash
sudo chgrp admin /volume2/Media
sudo chmod 2770 /volume2/Media
docker restart plex
```

Corrected state:

```text
drwxrws--- root admin /volume2/Media
```

The leading `2` in `2770` enables setgid so newly created children inherit the `admin` group.

### Verification

Test access as Plex's actual runtime identity:

```bash
docker exec -u 1001:10 plex ls -lh "/media/tv/Your Friends & Neighbors/Season 2/"
```

Check for new permission errors:

```bash
docker exec plex grep -i "Permission denied" \
  "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log" | tail -20
```

Playback succeeded after correcting the top-level group and permissions and restarting Plex.

For reusable ownership, mode, path traversal, and Docker bind-mount troubleshooting guidance, see [`../linux/filesystem-permissions.md`](../linux/filesystem-permissions.md).
