# qBittorrent and Gluetun

## Purpose

Runs qBittorrent through Gluetun so all torrent traffic uses the configured VPN tunnel.

## Deployment

- Containers: `gluetun` and `qbittorrent`
- Network: external `media-net`
- qBittorrent network mode: `service:gluetun`
- Web interface: port `8888` published by Gluetun
- Torrent port: `6888` TCP and UDP
- qBittorrent config: `/volume1/docker/qbittorrent/config:/config`
- Media: `/volume2/Media:/data`
- Watchtower: disabled for both containers

## Required variables

Copy `.env.example` to a local `.env` file and provide the VPN credentials used by the Compose file. Never commit real credentials.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=gluetun --filter name=qbittorrent
docker inspect --format='{{.State.Health.Status}}' gluetun
docker logs --tail 100 gluetun
docker logs --tail 100 qbittorrent
```

qBittorrent depends on Gluetun's network namespace. Treat them as one recovery unit and keep Watchtower rolling restarts disabled.