# TeslaMate

## Overview

TeslaMate provides private, self-hosted Tesla driving, charging, efficiency, and location-history analytics. The deployment runs on the UGREEN NAS as a Portainer stack and uses PostgreSQL for storage, Grafana for dashboards, and Mosquitto for MQTT telemetry.

## Current deployment

- Portainer stack: `teslamate`
- TeslaMate image: `teslamate/teslamate:4.0.1`
- Grafana image: `teslamate/grafana:4.0.1`
- PostgreSQL image: `postgres:18-trixie`
- Mosquitto image: `eclipse-mosquitto:2`
- TeslaMate UI: `http://NAS-IP:4000`
- Grafana UI: `http://NAS-IP:3003`
- Application network: `teslamate-app`
- Internal database network: `teslamate-database`
- PostgreSQL and MQTT do not publish host ports.
- All four containers are excluded from unattended Watchtower updates.

The version-controlled stack definition is stored in `docker/teslamate/docker-compose.yml`.

## Authentication

TeslaMate authentication uses Tesla OAuth access and refresh tokens entered through the private TeslaMate interface. Tokens and the TeslaMate encryption key must never be committed to Git.

The encryption key must be retained in a secure password manager or backup location. Losing it can make the encrypted Tesla tokens stored in PostgreSQL unusable.

A Tesla virtual key is not installed. The deployment is intended for analytics and read-only telemetry rather than vehicle-command access.

## Grafana

Grafana is available on host port `3003` and uses the TeslaMate PostgreSQL database as its data source.

Grafana must be attached to both Docker networks:

- `teslamate-app` for reachable web access
- `teslamate-database` for access to PostgreSQL

During deployment, Grafana was initially attached to the wrong network combination. Connecting it to both networks restored access while keeping the database network internal.

Anonymous access and user self-registration are disabled. Analytics reporting, update checks, and Gravatar are also disabled.

## MQTT

Mosquitto provides internal MQTT telemetry for TeslaMate. The Compose service name is `mosquitto`, so TeslaMate must use:

```yaml
MQTT_HOST: mosquitto
```

Do not use `cap_drop: ALL` on the Mosquitto container. The image entrypoint needs sufficient privileges to set ownership on `/mosquitto/data` before dropping to the `mosquitto` user. Applying `cap_drop: ALL` caused startup privilege errors.

A healthy Mosquitto log shows a TeslaMate MQTT client connection.

## Upgrade history

The initial TeslaMate `3.1.0` deployment returned a Tesla Fleet API `403 Forbidden` response while requesting vehicles. TeslaMate and its matching Grafana image were upgraded together to `4.0.1`, which restored vehicle discovery.

TeslaMate and the TeslaMate Grafana image should remain on matching versions unless the upstream release notes explicitly state otherwise.

PostgreSQL major-version upgrades must never be performed through unattended image updates. Back up and validate the database before changing the PostgreSQL major version.

## Geofence and charging cost

The Home geofence is configured in TeslaMate. Its electricity rate is set to an effective cost of `$0.13/kWh` so home charging sessions receive a useful cost estimate.

Review this value whenever the electricity rate changes. Charging costs outside the Home geofence may need to be entered or corrected based on the charging provider and session details.

## Validation completed

The deployment was validated with:

- Successful Tesla account authentication and vehicle discovery
- Reachable TeslaMate and Grafana interfaces
- A healthy PostgreSQL database
- A healthy Mosquitto connection
- The first recorded drive
- The first recorded charging session
- The Home geofence and home electricity rate

## Home Assistant integration plan

The next phase is a Home Assistant Tesla dashboard using useful read-only TeslaMate MQTT entities. The integration should prioritize status and historical context without adding vehicle-command access.

Candidate entities include:

- Vehicle state and connectivity
- Battery level and estimated range
- Charging state, power, energy added, and time remaining
- Plugged-in status
- Odometer
- Inside and outside temperature
- Location or geofence state, with privacy considered before exposing it to other dashboards

MQTT must be made reachable to Home Assistant before entities can be consumed. The current Mosquitto broker is intentionally internal to `teslamate-app` and does not publish a host port. Any change should preserve authentication and avoid exposing an unauthenticated broker to the LAN.

## Verification

```bash
docker ps --filter name=teslamate
docker logs --tail 100 teslamate
docker logs --tail 50 teslamate-mosquitto
curl -I http://127.0.0.1:4000
curl -I http://127.0.0.1:3003
```

Expected results:

- All four containers are running.
- TeslaMate logs show successful database and MQTT connectivity.
- Mosquitto logs show a TeslaMate client connection.
- TeslaMate returns an HTTP response on port `4000`.
- Grafana normally returns an HTTP `302` redirect to `/login` on port `3003`.

## Backup and recovery

Back up the PostgreSQL database and the TeslaMate encryption key together before application or database upgrades. Treat every backup as sensitive because it contains detailed vehicle and location history.

A basic logical backup can be created from the NAS with:

```bash
docker exec teslamate-database pg_dump \
  -U teslamate \
  -d teslamate \
  -Fc \
  -f /tmp/teslamate.dump

docker cp teslamate-database:/tmp/teslamate.dump ./teslamate.dump
```

Encrypt the resulting dump before storing it outside the NAS. Validate that the encryption key and current environment-variable values are available before attempting recovery.

Recovery should be tested in an isolated database before replacing the production volume.

## Security boundaries

- Keep TeslaMate and Grafana available only on the LAN or through Tailscale.
- Do not create public Cloudflare hostnames or router port-forwards for either interface.
- Keep PostgreSQL and MQTT unexposed unless a documented integration requires a controlled exception.
- Never commit real passwords, Tesla tokens, or the encryption key.
- Do not install a Tesla virtual key unless a later requirement explicitly needs command access.
- Keep all TeslaMate containers excluded from unattended Watchtower updates.

## Known issues and lessons

- TeslaMate `3.1.0` could not discover the vehicle because the Fleet API returned `403 Forbidden`; upgrading TeslaMate and Grafana together to `4.0.1` resolved it.
- Grafana must join the application and internal database networks.
- Mosquitto fails during its ownership and privilege-drop sequence when `cap_drop: ALL` is applied.
- `MQTT_HOST` must resolve to the Compose service name `mosquitto`.
- OAuth tokens should be generated only through a trusted workflow and entered directly into the private TeslaMate interface.
