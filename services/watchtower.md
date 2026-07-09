# Watchtower

## Purpose

Watchtower monitors Docker images and recreates containers when updates are available.

In this homelab, Watchtower is currently deployed as a Portainer-managed stack. It is intentionally configured conservatively after the July 2026 stack cleanup so it remains easy to inspect and recover.

---

## Deployment

| Setting | Value |
| --- | --- |
| Host | UGREEN DXP4800 Plus |
| Stack name | `watchtower` |
| Container name | `watchtower` |
| Image | `containrrr/watchtower:latest` |
| Deployment method | Portainer stack |
| Compose source | Portainer Editor |
| Supporting host path | `/volume1/docker/watchtower/docker-compose.yml` |

The Watchtower stack was redeployed through Portainer on 2026-07-08 so the Portainer **Editor** tab is available again.

---

## Current Configuration

Important settings:

```yaml
TZ: America/Chicago
DOCKER_API_VERSION: "1.40"
WATCHTOWER_CLEANUP: "true"
WATCHTOWER_REMOVE_VOLUMES: "false"
WATCHTOWER_LABEL_ENABLE: "false"
WATCHTOWER_INCLUDE_STOPPED: "false"
WATCHTOWER_INCLUDE_RESTARTING: "true"
WATCHTOWER_ROLLING_RESTART: "false"
WATCHTOWER_TIMEOUT: "30s"
WATCHTOWER_LOG_FORMAT: pretty
WATCHTOWER_SCHEDULE: "0 0 12 * * *"
```

Schedule meaning:

```text
Every day at 12:00 PM Central time
```

---

## Docker API Compatibility

Watchtower previously entered a restart loop with this error:

```text
client version 1.25 is too old. Minimum supported API version is 1.40
```

The fix was to explicitly set:

```yaml
DOCKER_API_VERSION: "1.40"
```

Keep this value in place unless Docker Engine or Watchtower behavior changes and the setting is retested.

---

## Rolling Restart Disabled

Rolling restart is disabled:

```yaml
WATCHTOWER_ROLLING_RESTART: "false"
```

Reason: qBittorrent uses Gluetun as its network namespace with:

```yaml
network_mode: service:gluetun
```

Watchtower reported that qBittorrent depends on another container and that this is not compatible with rolling restarts. Disabling rolling restarts prevents Watchtower from failing against dependency-linked containers.

---

## Current Update Strategy

Current behavior:

```yaml
WATCHTOWER_LABEL_ENABLE: "false"
```

This means Watchtower checks all containers except containers explicitly disabled by label.

Future improvement: convert Watchtower to a label-based opt-in model so only low-risk containers are automatically updated. That project should include a backup plan, a rollback plan, and explicit labels on selected containers.

Recommended future opt-in setting:

```yaml
WATCHTOWER_LABEL_ENABLE: "true"
```

Recommended opt-in label:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

---

## Verification Commands

Check container status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}" | grep watchtower
```

Expected result:

```text
watchtower   Up ... (healthy)   watchtower
```

View recent logs:

```bash
docker logs --tail=50 watchtower
```

Expected healthy startup includes:

```text
Watchtower 1.7.1
Checking all containers
Scheduling first run
```

Inspect environment:

```bash
docker inspect watchtower --format '{{range .Config.Env}}{{println .}}{{end}}' | sort
```

---

## Recovery

If Watchtower causes problems, stop it first:

```bash
docker stop watchtower
```

To recreate from the host-side Compose file:

```bash
cd /volume1/docker/watchtower
docker compose up -d
```

Preferred long-term management is through the Portainer stack named `watchtower`.

---

## Cleanup History

### 2026-06-28

An older Watchtower compose folder was archived:

```text
/volume1/docker/portainer/compose-archive/watchtower-old-3-2026-06-28-1542
```

### 2026-07-08

Watchtower was recreated as a proper Portainer-managed stack after a restart loop was fixed.

Key fixes:

- Added `DOCKER_API_VERSION=1.40`
- Disabled rolling restarts
- Restored Portainer Editor access
- Verified the container became healthy

---

## Lessons Learned

- Watchtower should be treated carefully because it can recreate critical infrastructure containers.
- `DOCKER_API_VERSION=1.40` is required in this environment.
- `WATCHTOWER_ROLLING_RESTART=false` is required with the current qBittorrent/Gluetun dependency pattern.
- Label-based opt-in automatic updates are still the preferred future state, but should be implemented as a separate change with backups and rollback steps.
