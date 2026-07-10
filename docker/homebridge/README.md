# Homebridge

## Purpose

Provides Apple Home integration for devices and services that do not natively support HomeKit.

## Deployment

- Container: `Homebridge`
- Image: `homebridge/homebridge`
- Network mode: `host`
- Web interface: port `8581`
- Persistent data: `/volume1/docker/homebridge:/homebridge`
- Extra package: `ffmpeg`
- Restart policy: `always`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=Homebridge
docker logs --tail 100 Homebridge
curl -I http://127.0.0.1:8581
```

Because this stack uses host networking, review port conflicts before changing its configuration.