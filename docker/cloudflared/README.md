# Cloudflared

## Purpose

Runs the Cloudflare Tunnel connector used to publish selected homelab services without exposing additional inbound ports.

## Deployment

- Container: `cloudflared`
- Image: `cloudflare/cloudflared:latest`
- Network: external `media-net`
- Restart policy: `unless-stopped`
- Watchtower: opted in

## Required variables

Copy `.env.example` to a local `.env` file and provide:

```env
CF_TUNNEL_TOKEN=replace-me
```

Never commit the real tunnel token.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=cloudflared
docker logs --tail 100 cloudflared
```

The command includes `--no-autoupdate`, so container image updates are handled externally by Watchtower.