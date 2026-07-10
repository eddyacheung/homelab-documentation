# Unbound

## Purpose

Provides recursive DNS resolution upstream of Pi-hole.

## Deployment

- Container: `unbound`
- Image: `mvance/unbound:latest`
- Network: external `media-net`
- Restart policy: `unless-stopped`
- Health check: recursive lookup against `127.0.0.1`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=unbound
docker inspect --format='{{.State.Health.Status}}' unbound
docker logs --tail 100 unbound
docker exec unbound drill @127.0.0.1 cloudflare.com
```

Pi-hole depends on reliable upstream resolution, so validate DNS after every Unbound change.