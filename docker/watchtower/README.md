# Watchtower

## Purpose

Checks opted-in containers for image updates and recreates them on the configured schedule.

## Deployment

- Container: `watchtower`
- Image: `containrrr/watchtower:latest`
- Docker socket: mounted read-only
- Schedule: daily at 12:00 PM Central
- Cleanup: enabled
- Label mode: enabled
- Rolling restart: disabled
- Docker API version: `1.40`

## Update policy

Only containers with this label are eligible:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

Dependency-sensitive and stateful services should remain manual unless deliberately approved.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=watchtower
docker logs --tail 100 watchtower
```

Healthy startup should include:

```text
Only checking containers using enable label
```

Keep rolling restarts disabled because qBittorrent shares Gluetun's network namespace.