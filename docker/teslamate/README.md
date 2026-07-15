# TeslaMate

## Purpose

Provides private Tesla driving, charging, efficiency, and location-history analytics with PostgreSQL storage, Grafana dashboards, and MQTT telemetry.

## Deployment

- Managed as the Portainer stack `teslamate`.
- Containers: `teslamate`, `teslamate-database`, `teslamate-grafana`, and `teslamate-mosquitto`.
- Images: `teslamate/teslamate:4.0.1`, `teslamate/grafana:4.0.1`, `postgres:18-trixie`, and `eclipse-mosquitto:2`.
- TeslaMate: `http://NAS-IP:4000`.
- Grafana: `http://NAS-IP:3003`.
- PostgreSQL and MQTT do not publish host ports.
- Networks: `teslamate-app` and internal `teslamate-database`.
- Persistent data uses named Docker volumes.

## Required variables

Enter the variables from `.env.example` in Portainer's stack environment-variable section. Never commit the real database password, Grafana password, encryption key, access token, or refresh token.

The TeslaMate encryption key must be backed up securely. Losing it can make the encrypted Tesla tokens stored in PostgreSQL unusable.

## Portainer deployment

1. Open **Stacks** in Portainer and create or edit the `teslamate` stack.
2. Paste `docker-compose.yml` into the Web editor.
3. Add the four required environment variables.
4. Deploy or update the stack.
5. Generate Tesla access and refresh tokens using a trusted OAuth token workflow, then enter them only in the private TeslaMate interface.

## Verified fixes

- Grafana must join both `teslamate-app` and `teslamate-database`; otherwise its published web port may not be reachable.
- Mosquitto must not use `cap_drop: ALL`. Its entrypoint needs to set ownership on `/mosquitto/data` and drop privileges to the `mosquitto` user.
- `MQTT_HOST` should use the Compose service name `mosquitto`.
- TeslaMate 3.1.0 returned a Fleet API `403 Forbidden` when requesting vehicles. Updating TeslaMate and its matching Grafana image to 4.0.1 resolved vehicle discovery.

## Verification

```bash
docker ps --filter name=teslamate
docker logs --tail 100 teslamate
docker logs --tail 50 teslamate-mosquitto
curl -I http://127.0.0.1:4000
curl -I http://127.0.0.1:3003
```

A healthy Mosquitto log includes a TeslaMate MQTT client connection. Grafana normally returns an HTTP 302 redirect to `/login`.

## Security and recovery

- Keep TeslaMate and Grafana LAN/Tailscale-only.
- Do not create a Cloudflare hostname or router port-forward.
- Do not install a Tesla virtual key unless command access is explicitly required later.
- Disable unattended Watchtower updates for all four containers.
- Back up PostgreSQL and the encryption key before application or PostgreSQL upgrades.
- Treat backups as sensitive because they contain detailed vehicle and location history.
