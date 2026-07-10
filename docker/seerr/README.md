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