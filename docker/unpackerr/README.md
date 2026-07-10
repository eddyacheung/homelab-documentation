# Unpackerr

## Purpose

Extracts archived downloads so Radarr and Sonarr can import completed media automatically.

## Deployment

- Container: `unpackerr`
- Image: `golift/unpackerr:latest`
- Network: external `media-net`
- Config and logs: `/volume1/docker/unpackerr/config:/config`
- Media: `/volume2/Media:/data`
- Integrations: Radarr and Sonarr

## Required variables

Copy `.env.example` to a local `.env` file and provide:

```env
SONARR_API_KEY=replace-me
RADARR_API_KEY=replace-me
```

Never commit real API keys.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=unpackerr
docker logs --tail 100 unpackerr
```

Deployment is complete. Final operational validation will occur when the next naturally archived download is processed.