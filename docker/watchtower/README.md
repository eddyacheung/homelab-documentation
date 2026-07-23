# Watchtower

## Purpose

Watchtower checks explicitly opted-in containers for image updates on a daily schedule. Low-risk containers may update automatically, while stateful, critical, or dependency-sensitive containers can be placed in monitor-only mode for manual review.

## Deployment

- Container: `watchtower`
- Image: `containrrr/watchtower:latest`
- Docker socket: mounted read-only
- Schedule: daily at 12:00 PM Central
- Cleanup: enabled
- Label mode: enabled
- Rolling restart: disabled
- Docker API version: `1.40`
- Notifications: Home Assistant webhook through Shoutrrr generic webhook

## Update policy

Only containers with the enable label are included in Watchtower scans.

### Automatic updates

Use this label for low-risk containers approved for automatic updates:

```yaml
labels:
  com.centurylinklabs.watchtower.enable: "true"
```

### Monitor-only updates

Use both labels for stateful, critical, or dependency-sensitive containers that should only generate an update notification:

```yaml
labels:
  com.centurylinklabs.watchtower.enable: "true"
  com.centurylinklabs.watchtower.monitor-only: "true"
```

The qBittorrent and Gluetun containers use monitor-only mode. They share a network namespace and should be updated together through their Compose project rather than independently.

## Notification behavior

Watchtower sends report notifications to a Home Assistant webhook. The notification includes:

- scanned, updated, and failed container counts
- affected container and image names
- current and latest image IDs when available
- a reminder of the manual Docker Compose update commands
- a Portainer update-stack alternative

The real webhook URL is stored in a local `.env` file and is not committed to Git. Copy `.env.example` to `.env` and replace the placeholder webhook ID.

The webhook must use the NAS address, not `127.0.0.1`. Inside the Watchtower container, `127.0.0.1` points back to Watchtower itself and causes a connection-refused error.

## Manual update workflow

For a monitor-only stack, first identify its Portainer Compose directory and project name, then run:

```bash
cd /volume1/docker/portainer/compose/STACK_NUMBER
docker compose -p PROJECT_NAME pull
docker compose -p PROJECT_NAME up -d
```

Example for qBittorrent and Gluetun:

```bash
cd /volume1/docker/portainer/compose/47
docker compose -p qbittorrent pull
docker compose -p qbittorrent up -d
```

Portainer alternative:

1. Open the matching stack.
2. Select **Update the stack**.
3. Enable image re-pull when appropriate.
4. Redeploy the stack.

## Deploy

```bash
cp .env.example .env
# Edit .env and set the real Home Assistant webhook ID.
docker compose up -d
```

For the Portainer-managed deployment, update the stack from the Portainer editor using the complete Compose YAML and the corresponding environment variable.

## Verify

```bash
docker ps --filter name=watchtower
docker logs --tail 100 watchtower
```

Healthy startup should include:

```text
Watchtower 1.7.1
Using notifications: generic
Only checking containers using enable label
Scheduling first run: YYYY-MM-DD 12:00:00 -0500 CDT
```

There should be no notification error resembling:

```text
Failed to send shoutrrr notification
connect: connection refused
```

To verify monitor-only labels on a container:

```bash
docker inspect CONTAINER_NAME --format \
'enable={{index .Config.Labels "com.centurylinklabs.watchtower.enable"}} monitor-only={{index .Config.Labels "com.centurylinklabs.watchtower.monitor-only"}}'
```

Expected output for a monitor-only container:

```text
enable=true monitor-only=true
```

## Operational notes

- Keep rolling restarts disabled because qBittorrent shares Gluetun's network namespace.
- Do not use one generic Compose project name for every stack.
- Always run manual update commands from the correct Portainer Compose directory with the correct `-p` project name.
- Prefer complete YAML replacements when changing nested Compose configuration to avoid indentation errors.
