# Automated Docker Updates and Uptime Monitoring

**Date:** 2026-10-20 to 2026-10-21  
**Host:** UGREEN DXP4800 Plus (UGOS Pro)  
**Change type:** Container update automation, health checks, DNS stability, service monitoring

## Summary

Moved from manually updating containers with the archived `containrrr/watchtower` to the maintained `nickfedor/watchtower` fork, opted five more applications into unattended updates, fixed Plex's health check, and expanded Uptime Kuma monitoring from 6 to 14 services. Discord test notification succeeded. Sensitive configuration values are intentionally omitted.

**Scope:** This is a change record based on commands and validation outputs observed during deployment, **not** a copy of the complete live Compose files. The Portainer Compose definitions and Uptime Kuma database remain the operational sources of truth.

## Watchtower migration

- **Portainer Compose project:** `watchtower`
- **Host Compose file:** `/volume1/docker/portainer/compose/48/docker-compose.yml`
- **Image:** `containrrr/watchtower:latest` → `nickfedor/watchtower:latest`
- **Validated runtime:** Watchtower **1.23.1**, Docker API **1.40**, Docker health **healthy**
- **Schedule:** Changed `WATCHTOWER_SCHEDULE` from `0 0 12 * * *` (noon) to `0 0 3 * * *` (**03:00 America/Chicago**)
- **Cooldown:** Added `WATCHTOWER_COOLDOWN_DELAY: "48h"`. Configuration was deployed, but a real update-delay event was **not independently verified**.
- **Policy:** Retained `WATCHTOWER_LABEL_ENABLE=true`, `WATCHTOWER_CLEANUP=true`, `WATCHTOWER_REMOVE_VOLUMES=false`, `WATCHTOWER_ROLLING_RESTART=false`, `WATCHTOWER_INCLUDE_STOPPED=false`, `WATCHTOWER_INCLUDE_RESTARTING=true`, and `WATCHTOWER_TIMEOUT=30s`.
- **Docker socket mount:** `/var/run/docker.sock:/var/run/docker.sock:ro`.
- **Notifications:** Preserved a generic Home Assistant webhook and changed the report template to show failures only. Watchtower recognized the `generic` notification provider at startup. **Failure-alert delivery has not been tested end to end.** Keep webhook URLs and secrets out of Git.
- **Replacement:** Redeployed the existing Compose project instead of running two scheduled updater containers.
- **Observed next scheduled run:** 2026-10-21 03:00 CDT.

The original Watchtower 1.7.1 failed with `client version 1.25 is too old; Minimum supported API version is 1.40`. Supplying `DOCKER_API_VERSION=1.40` allowed the one-time update; the migrated fork also started successfully with the explicit API version.

### Labels and eligibility

Automatic updates require `com.centurylinklabs.watchtower.enable=true` without `com.centurylinklabs.watchtower.monitor-only=true` under the current opt-in configuration. A monitor-only label still permits update detection, but prevents Watchtower from recreating that container.

| Service | Portainer Compose stack | Change |
| --- | --- | --- |
| Plex | `49` | Removed monitor-only label; retained enable=true |
| Bazarr | `61` | Added enable=true |
| Open WebUI | `40` | Removed monitor-only label; retained enable=true |
| Homebridge | `2` | Removed monitor-only label; retained enable=true |
| Scrypted | `55` | Removed monitor-only label; retained enable=true |

All five were recreated via their own Compose services; subsequent `docker inspect` confirmed they were running with `enabled=true` and no monitor-only value. Plex, Open WebUI, and Homebridge passed Docker health checks; Bazarr and Scrypted have no configured Docker health check.

Other existing automatic-update labels (such as Sonarr, Radarr, Prowlarr and Tautulli) were left as-is. **Protected:** Pi-hole, Unbound, Gluetun, qBittorrent, Home Assistant, Portainer, and other sensitive networking/infrastructure remain monitor-only or excluded as previously configured. Database/finance service exclusions were not expanded. Maintain Gluetun/qBittorrent's coupled update policy and keep rolling restarts disabled.

**Important caveat:** The first manually run `watchtower --run-once --cleanup` command **omitted** `--label-enable` and therefore scanned more containers than the scheduled updater. Prefer the scheduled label-based policy; for an equivalent manual run, use `--label-enable` and account for monitor-only labels.

## Plex health-check repair

The Plex image was updated to `ghcr.io/linuxserver/plex:latest`; the new running image ID began `6d4ea304e00e`. Its Compose health check failed with:

```text
/bin/sh: 1: wget: not found
```

Changed the Plex Compose health check from a `wget --spider` request to a `curl -fsS` request against `http://localhost:32400/identity`. Plex was recreated; Docker eventually reported `healthy`. The fix is persisted in the Plex Compose file in stack 49. Mounted media/configuration were preserved. Do not install `wget` interactively inside the container as a workaround.

## Uptime Kuma monitoring expansion

- **Version observed:** `1.23.17`
- **Container/network:** `uptime-kuma`, `media-net`
- **Dashboard:** `http://192.168.10.101:3001`
- **Persistent data:** `/volume1/docker/uptime-kuma -> /app/data`
- **Initial monitors (6):** Plex, Prowlarr, Radarr, `Seer` (display name in Kuma), Sonarr, qBit.
- **Added monitors (8):** Unbound, Bazarr, Open WebUI, Homebridge, Scrypted, Home Assistant, Portainer, Pi-hole DNS.
- **Final state:** All **14** monitors showed `UP` in latest-heartbeat checks.
- **New monitor settings:** 60-second checks, two retries, Discord notification `media stack`; HTTP successful status ranges `200-299` and `300-399`.
- **Notification delivery:** Uptime Kuma's **Discord** `media stack` notification was tested successfully. This is separate from the Watchtower → Home Assistant webhook.

New monitors were created with temporary `python:3.11-slim` containers and `uptime-kuma-api==1.2.1`, using Uptime Kuma credentials entered interactively. The helper containers were removed after execution. No direct SQLite writes were made. The NAS's system Python lacked `ensurepip`, so creating a host virtual environment failed; running the helper in Docker avoided installing packages in UGOS.

### Monitored service endpoints

| Service | Monitoring target / approach |
| --- | --- |
| Bazarr | `http://192.168.10.101:6767` |
| Open WebUI | `http://192.168.10.101:3002` |
| Portainer | `http://portainer:9000` |
| Homebridge | `http://172.26.0.1:8581` |
| Home Assistant | `http://172.26.0.1:8123` |
| Scrypted | `https://172.26.0.1:10443` (TLS verification exception for local/self-signed certificate) |
| Pi-hole DNS | Resolve `example.com` via `192.168.10.250:53` |
| Unbound DNS | Resolve `example.com` via `172.26.0.14:53` |

`media-net` uses subnet `172.26.0.0/16` and gateway `172.26.0.1`. The host-networked services Home Assistant, Homebridge and Scrypted responded to the NAS host's LAN address but **timed out when accessed from inside Uptime Kuma via `192.168.10.101`**. Connecting from Uptime Kuma to the Docker bridge gateway `172.26.0.1` instead returned HTTP 200, 200, and 302 respectively. Their Kuma monitor URLs were updated via API and all became `UP`. No Docker firewall/routing modifications were required.

A DNS monitor using `dns_resolve_server=unbound` failed with `Invalid IP address: [unbound]:53`; changing it to a numeric resolver IP worked. The `accepted_statuscodes=["200-399"]` API argument was also invalid and was replaced with `["200-299", "300-399"]`.

## Unbound static network address

- **Stack:** `/volume1/docker/portainer/compose/44/docker-compose.yml`
- **Image:** `mvance/unbound:latest`
- **Network:** external `media-net`
- **Reserved container address:** `172.26.0.14`
- **Watchtower labels:** `enable=true`, `monitor-only=true` (protected)
- **Health check:** `drill @127.0.0.1 cloudflare.com`

Changed the service's Compose network stanza from list notation to:

```yaml
services:
  unbound:
    networks:
      media-net:
        ipv4_address: 172.26.0.14
networks:
  media-net:
    external: true
```

The following were observed after deployment:

```text
IP: 172.26.0.14
Health: healthy
Configured static IP: 172.26.0.14
Uptime Kuma Unbound: UP
```

This keeps the Kuma DNS monitor valid during normal container recreations while `media-net` retains its subnet and the address remains unoccupied. Do not delete/recreate or renumber `media-net` without revisiting these endpoints.

## Operational verification

```bash
docker logs watchtower --tail 35
docker inspect watchtower --format '{{.State.Health.Status}}'
docker inspect plex --format '{{.State.Health.Status}}'

for c in plex bazarr open-webui homebridge scrypted; do
  docker inspect "$c" --format '{{.Name}} enabled={{index .Config.Labels "com.centurylinklabs.watchtower.enable"}} monitor-only={{index .Config.Labels "com.centurylinklabs.watchtower.monitor-only"}}'
done

docker inspect unbound --format 'IP={{(index .NetworkSettings.Networks "media-net").IPAddress}} Static={{(index .NetworkSettings.Networks "media-net").IPAMConfig.IPv4Address}} Health={{.State.Health.Status}}'
```

Use the Uptime Kuma dashboard to confirm the 14 monitor states and test notification delivery. Avoid posting entire `docker inspect` environment arrays or `docker-compose.yml` files publicly without removing tokens, webhook IDs, and passwords.

## Remaining limitations

- Watchtower's **first scheduled update after migration**, the **48-hour cooldown behavior**, and a **real failed-update Home Assistant notification** have not yet been independently observed.
- Discord's **test** notification succeeded, but an actual down/recovery notification sequence was not deliberately induced.
- Uptime Kuma reports reachability and DNS resolution; it is not an automatic rollback or application repair system.
- The Watchtower container itself did not have an explicit enable=true label in the initial inventory; its own future updates are not confirmed automated.
- Backups and tested recovery procedures remain necessary for stateful services.

## Recovery / rollback pointers

- Watchtower Compose: stack 48; backup `docker-compose.yml.bak` was created before migration, and `docker-compose.yml.before-notifications.bak` before the notification template change.
- Plex Compose: stack 49; health-check edit created `docker-compose.yml.bak`.
- Five application stacks: timestamped `docker-compose.yml.bak-YYYYMMDD-HHMMSS` backups created by the label-change script.
- Unbound Compose: stack 44; `docker-compose.yml.bak-before-static-ip` created before adding the static address.
- Prefer reviewing the backup diff and reverting a single affected Compose stack rather than restoring all configurations at once.
