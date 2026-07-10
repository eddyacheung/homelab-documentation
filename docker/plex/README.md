# Plex

## Purpose

Runs Plex Media Server for the local media library and shared remote users.

## Deployment

- Container: `plex`
- Image: `ghcr.io/linuxserver/plex:latest`
- Network mode: `host`
- Hardware transcoding: `/dev/dri`
- Config: `/volume1/docker/plexhw:/config`
- Transcode: `/volume1/docker/plexhw/transcode:/transcode`
- Media: `/volume2/Media:/media:ro`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=plex
docker logs --tail 100 plex
curl -I http://127.0.0.1:32400/web
```

Back up the Plex config directory before rebuilding. The media mount is intentionally read-only.