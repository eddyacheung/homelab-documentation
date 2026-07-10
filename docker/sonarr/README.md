# Sonarr

## Purpose

Automates TV-series monitoring, acquisition, importing, and library organization.

## Deployment

- Container: `sonarr`
- Image: `lscr.io/linuxserver/sonarr:latest`
- Published port: `8989:8989`
- Network: external `media-net`
- Config: `/volume1/docker/sonarr/config:/config`
- Media: `/volume2/Media:/data`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=sonarr
docker logs --tail 100 sonarr
curl -I http://127.0.0.1:8989
```

Back up the config directory before rebuilding. Preserve the shared `/data` path because it supports hardlinks and consistent download-client paths.