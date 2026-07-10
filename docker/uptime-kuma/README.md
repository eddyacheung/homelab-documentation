# Uptime Kuma

## Purpose

Provides availability monitoring and outage notifications for important homelab services.

## Deployment

- Container: `uptime-kuma`
- Image: `louislam/uptime-kuma:latest`
- Published port: `3001:3001`
- Network: external `media-net`
- Persistent data: `/volume1/docker/uptime-kuma:/app/data`
- Host access: `host.docker.internal:host-gateway`
- Watchtower: opted in

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=uptime-kuma
docker logs --tail 100 uptime-kuma
curl -I http://127.0.0.1:3001
```

Back up the persistent data directory because it contains monitors, users, history, and notification configuration.