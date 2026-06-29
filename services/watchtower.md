# Watchtower

## Purpose

Watchtower keeps selected Docker containers updated by checking for newer container images and recreating containers when updates are available.

This homelab uses Watchtower in a conservative opt-in model instead of updating every container automatically.

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Container name:** `watchtower`
- **Image:** `containrrr/watchtower:latest`
- **Deployment method:** Docker Compose
- **Compose directory:** `/volume1/docker/watchtower`
- **Compose file:** `/volume1/docker/watchtower/docker-compose.yml`

## Update Strategy

Watchtower is configured for label-based updates only:

```yaml
WATCHTOWER_LABEL_ENABLE: "true"
```

Containers are only updated automatically when this label is present:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

This prevents critical services from being unexpectedly recreated during image updates.

## Schedule

Watchtower checks for updates weekly:

```yaml
WATCHTOWER_SCHEDULE: "0 0 4 * * SUN"
```

Schedule meaning:

```text
Sunday at 4:00 AM
```

Timezone:

```yaml
TZ: America/Chicago
```

## Current Auto-Update Containers

The following containers are currently opted into automatic updates:

- Homarr
- Uptime Kuma
- Open WebUI

These services were selected because they are lower-risk than DNS, database, proxy, or core media services.

## Manual Update Containers

The following containers should remain manually updated:

- Portainer
- Pi-hole
- Unbound
- Nginx Proxy Manager
- Plex
- qBittorrent
- Sonarr
- Radarr
- Prowlarr
- Seerr
- PostgreSQL
- Homebridge

These services are infrastructure, networking, database-backed, downloader, proxy, or core media services where release notes should be reviewed before updating.

qBittorrent should remain excluded at least until the future Gluetun + NordVPN project is completed and a clear rollback plan exists.

## Key Configuration

Important settings:

```yaml
TZ: America/Chicago
WATCHTOWER_LABEL_ENABLE: "true"
WATCHTOWER_CLEANUP: "true"
WATCHTOWER_REMOVE_VOLUMES: "false"
WATCHTOWER_INCLUDE_STOPPED: "false"
WATCHTOWER_INCLUDE_RESTARTING: "true"
WATCHTOWER_ROLLING_RESTART: "true"
WATCHTOWER_TIMEOUT: 30s
WATCHTOWER_LOG_FORMAT: pretty
WATCHTOWER_SCHEDULE: "0 0 4 * * SUN"
```

## Verification Commands

Check container health:

```bash
docker ps --filter name=watchtower
```

Inspect Watchtower environment:

```bash
docker inspect watchtower --format '{{ index .Config.Env }}'
```

Check which containers are opted in:

```bash
docker inspect Homarr --format '{{json .Config.Labels}}'
docker inspect uptime-kuma --format '{{json .Config.Labels}}'
docker inspect open-webui --format '{{json .Config.Labels}}'
```

Expected label:

```text
"com.centurylinklabs.watchtower.enable":"true"
```

Confirm intentionally excluded services do not have the opt-in label:

```bash
docker inspect plex --format '{{json .Config.Labels}}'
docker inspect sonarr --format '{{json .Config.Labels}}'
docker inspect radarr --format '{{json .Config.Labels}}'
docker inspect prowlarr --format '{{json .Config.Labels}}'
docker inspect qbittorrent --format '{{json .Config.Labels}}'
```

View recent logs:

```bash
docker logs watchtower --tail 50
```

## Cleanup Performed

An older Portainer-managed Watchtower compose folder existed under:

```text
/volume1/docker/portainer/compose/3
```

The active Watchtower container was verified to be managed from:

```text
/volume1/docker/watchtower/docker-compose.yml
```

The old Portainer compose folder was archived rather than deleted:

```text
/volume1/docker/portainer/compose-archive/watchtower-old-3-2026-06-28-1542
```

## Recovery

If Watchtower causes problems, stop it first:

```bash
docker stop watchtower
```

To recreate Watchtower from Compose:

```bash
cd /volume1/docker/watchtower
docker compose up -d
```

To disable automatic updates without removing Watchtower, remove the Watchtower opt-in label from individual service stacks.

## Lessons Learned

- Watchtower previously updated all containers automatically.
- It was migrated to a safer label-based opt-in configuration.
- Critical services should not be automatically updated until there is a clear rollback plan.
- Container labels should be managed through Compose or Portainer stack definitions, not by trying to modify running containers.
