# Radarr

## Purpose

Automates movie monitoring, acquisition, importing, and library organization.

## Deployment

- Container: `radarr`
- Image: `ghcr.io/linuxserver/radarr:latest`
- Published port: `7878:7878`
- Network: external `media-net`
- Config: `/volume1/docker/radarr/config:/config`
- Media: `/volume2/Media:/data`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=radarr
docker logs --tail 100 radarr
curl -I http://127.0.0.1:7878
```

Back up the config directory before rebuilding. Preserve the shared `/data` path because it supports hardlinks and consistent download-client paths.