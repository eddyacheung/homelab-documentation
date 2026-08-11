# Seerr

## Purpose

Provides the media-request interface and stores its application data in PostgreSQL.

## Deployment

- Containers: `Seerr` and `Seerr-DB`
- Images: `ghcr.io/seerr-team/seerr:latest` and `postgres:16`
- Published port: `5055:5055`
- Network: external `media-net`
- Seerr config: `/volume1/docker/seerr/config:/app/config`
- PostgreSQL data: `/volume1/docker/seerr/db:/var/lib/postgresql/data`

## Required variables

Copy `.env.example` to a local `.env` file and provide the PostgreSQL database name, user, and password. Use the same values for both services where referenced.

Never commit the real database credentials.

## Plex friends and request permissions

For friends who should be able to request media:

1. Share the desired Plex libraries with the friend's Plex account if they also need playback access.
2. Import/use that Plex identity in Seerr.
3. Grant `Request Movies` and/or `Request Series`.
4. Grant `Auto-Approve Movies` and/or `Auto-Approve Series` only when requests should go directly to Radarr/Sonarr without manual approval.
5. Leave administrative permissions such as user/settings/request management disabled for normal users.

The `Auto-Request` permission is separate from normal requesting. When enabled, supported items added to the user's Plex Watchlist can automatically become Seerr requests. Leave it disabled if requests should only be submitted explicitly from Seerr.

### 4K permissions

Seerr has separate `Request 4K` and `Auto-Approve 4K` permission trees. In this homelab, Radarr/Sonarr quality profiles are responsible for preferring 4K while allowing lower-quality fallback rather than maintaining separate normal and 4K libraries. Therefore the normal request path is sufficient unless the media architecture is later changed to dedicated 4K service instances/libraries.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=Seerr
docker logs --tail 100 Seerr-DB
docker logs --tail 100 Seerr
curl -I http://127.0.0.1:5055
```

Back up both the Seerr config and PostgreSQL data directories before rebuilding.
