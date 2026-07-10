# Prowlarr

## Purpose

Manages indexers and synchronizes them with Radarr and Sonarr.

## Deployment

- Container: `prowlarr`
- Image: `lscr.io/linuxserver/prowlarr:latest`
- Published port: `9696:9696`
- Network: external `media-net`
- Config: `/volume1/docker/prowlarr/config:/config`
- Media paths: `/volume2/Media` subdirectories for downloads, TV, and movies

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=prowlarr
docker logs --tail 100 prowlarr
curl -I http://127.0.0.1:9696
```

Back up the config directory before rebuilding. Confirm Radarr and Sonarr application connections after major changes.