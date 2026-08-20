# Uptime Kuma

## Purpose

Provides availability monitoring and outage notifications for important homelab services.

## Deployment

- Container: `uptime-kuma`
- Image: `louislam/uptime-kuma:latest`
- Published port: `3001:3001`
- Network: external `media-net`
- Persistent data: `/volume1/docker/uptime-kuma:/app/data`
- Host access: `host.docker.internal:host-gateway`
- Watchtower: opted in

## Notifications

Uptime Kuma uses a dedicated Discord webhook named **Uptime Kuma** that posts to:

```text
#automation-alerts
```

This replaces the previous use of the general Discord channel. The notification configuration remains assigned to the existing media-stack monitors, so service-down and recovery messages land in the shared automation-alert channel while retaining the Uptime Kuma webhook name/icon.

A separate **Radarr Downsizer** webhook also posts to `#automation-alerts`; the two integrations intentionally use different webhooks so Discord clearly identifies the source of each alert.

Do not commit Discord webhook URLs to this repository.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=uptime-kuma
docker logs --tail 100 uptime-kuma
curl -I http://127.0.0.1:3001
```

Back up the persistent data directory because it contains monitors, users, history, and notification configuration.