# 2026-07-08 Portainer Stack Cleanup

## Summary

Cleaned up several Docker and Portainer stack inconsistencies on the UGREEN NAS.

Primary goals:

- Remove stale or anonymous stack names.
- Restore Portainer Editor access for important stacks.
- Standardize stack names to match service names.
- Preserve working service configuration.
- Improve recovery documentation.

---

## Services Changed

| Service | Previous State | Current State |
| --- | --- | --- |
| qBittorrent / Gluetun | External/numeric stack `38` | Portainer-managed stack `qbittorrent` |
| Watchtower | Manual/recreated container, prior restart loop | Portainer-managed stack `watchtower` |
| Plex | Stack/project `plexnew` | Stack/project `plex` |
| Portainer | Limited stack, self-management attempted | Left running from host-side Compose after backup |

---

## qBittorrent / Gluetun

### Problem

Portainer showed qBittorrent and Gluetun under a numeric stack/project:

```text
38
```

The original Compose folder was missing, so the stack could not be cleanly edited. A stale empty `qbittorrent` stack record also existed.

### Fix

- Deleted the stale empty `qbittorrent` stack record.
- Backed up the live container configuration with `docker inspect`.
- Recreated the stack as `qbittorrent`.
- Attached Gluetun to `media-net`.
- Kept qBittorrent using Gluetun's network namespace:

```yaml
network_mode: service:gluetun
```

### Validation

Verified:

- Gluetun healthy.
- OpenVPN connected.
- qBittorrent running.
- Radarr, Sonarr, and Prowlarr could reach qBittorrent at `gluetun:8888`.
- Portainer Editor tab exists for the `qbittorrent` stack.

---

## Watchtower

### Problem

Watchtower entered a restart loop with Docker API compatibility errors:

```text
client version 1.25 is too old. Minimum supported API version is 1.40
```

It also failed when rolling restarts interacted with the qBittorrent/Gluetun dependency model.

### Fix

Recreated Watchtower as a Portainer-managed stack with:

```yaml
DOCKER_API_VERSION: "1.40"
WATCHTOWER_ROLLING_RESTART: "false"
```

Schedule:

```yaml
WATCHTOWER_SCHEDULE: "0 0 12 * * *"
```

### Validation

Verified:

```text
watchtower   Up ... (healthy)   watchtower
```

Portainer Editor tab exists for the `watchtower` stack.

---

## Plex

### Problem

The Plex container was already named `plex`, but the Portainer stack/project was named:

```text
plexnew
```

### Fix

- Backed up Plex Compose and inspect output.
- Deleted the `plexnew` stack.
- Recreated it as `plex` using the same bind mounts and settings.

### Validation

Verified:

```text
plex   Up ... (healthy)   plex
```

Plex libraries and settings remained intact because the same `/config` volume was reused.

---

## Portainer

### Work Performed

Backed up Portainer before attempting self-management cleanup:

```text
/volume1/docker/portainer-backup/
```

Backups included:

- `compose.yml`
- `portainer.db`
- Docker inspect output

A Portainer self-redeploy attempt caused temporary UI loss / 502 errors. Portainer was recovered over SSH:

```bash
cd /volume1/docker/portainer
docker compose up -d
```

### Decision

Do not pursue full Portainer self-management cleanup for now.

Reason:

- Benefit is small: mainly restoring an Editor tab.
- Risk/annoyance is higher because Portainer manages the UI used for the redeploy.
- Current Portainer Compose is saved at `/volume1/docker/portainer/compose.yml` and backups exist.

---

## Final Verified State

```text
plex          healthy   project: plex
watchtower    healthy   project: watchtower
qbittorrent   running   project: qbittorrent
gluetun       healthy   project: qbittorrent
portainer     running   project: portainer
```

Radarr, Sonarr, and Prowlarr download client tests passed against:

```text
Host: gluetun
Port: 8888
```

---

## Lessons Learned

- For `network_mode: service:gluetun`, Gluetun is the reachable Docker endpoint, not qBittorrent.
- Gluetun should be attached to `media-net` so media services can reach `gluetun:8888`.
- Watchtower rolling restarts are not compatible with the current qBittorrent/Gluetun dependency pattern.
- Watchtower requires `DOCKER_API_VERSION=1.40` in this environment.
- Portainer should be backed up before any self-management changes.
- Recreating stacks with clean names is safer when bind mounts preserve service data.
