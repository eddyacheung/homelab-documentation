# Recyclarr

## Purpose

Synchronizes TRaSH Guides quality definitions, quality profiles, and custom formats into Radarr and Sonarr.

## Deployment

- Container: `recyclarr`
- Image: `ghcr.io/recyclarr/recyclarr:8`
- Network: external `media-net`
- Config: `/volume1/docker/recyclarr/config:/config`
- Runtime user: `1000:1000`
- Schedule: handled inside the container configuration

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=recyclarr
docker logs --tail 100 recyclarr
docker exec recyclarr recyclarr sync --preview
```

The active profiles are documented in `services/recyclarr.md`. API keys belong in the mounted configuration and must never be committed.