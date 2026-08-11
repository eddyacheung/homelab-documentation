# Tautulli

## Purpose

Provides Plex playback monitoring, per-user history, stream diagnostics, bandwidth visibility, and watch statistics.

## Deployment

- Container: `tautulli`
- Image: `lscr.io/linuxserver/tautulli:latest`
- Network: external `media-net`
- Config: `/volume1/docker/tautulli/config:/config`
- Container port: `8181/tcp`
- No host port is published; access is through Nginx Proxy Manager.
- Local URL: `http://taut.home`
- PUID/PGID: `1001:10` (`eddy.cheung:admin`)
- Time zone: `America/Chicago`

## Plex connectivity

Plex runs with host networking. Tautulli reaches the Plex host through Docker's stable host alias:

```text
host.docker.internal:32400
```

The Compose stack defines:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

This replaced the temporary working route through a Docker bridge gateway such as `172.21.0.1`, which could change if Docker networks are recreated.

Secure connection is disabled for this local Docker-to-host path.

## Reverse proxy and DNS

Nginx Proxy Manager and Tautulli share `media-net`.

NPM proxy host:

```text
Domain: taut.home
Scheme: http
Forward hostname: tautulli
Forward port: 8181
Websockets: enabled
```

Pi-hole local DNS maps `taut.home` to the NAS/Nginx Proxy Manager address (`192.168.10.101`).

Traffic flow:

```text
Browser -> Pi-hole -> Nginx Proxy Manager -> media-net -> tautulli:8181
                                             |
                                             +-> host.docker.internal:32400 -> Plex
```

## Application configuration

- Activity logging ignore interval: `120` seconds.
- Keep history enabled for Plex users whose activity should be tracked.
- Guest access to the Tautulli UI is disabled for normal Plex users.
- Automatic backup interval: `6` hours.
- Backup retention: `14` days.
- Backup directory: `/config/backups`.

Because `/config` is bind-mounted, the Tautulli database, configuration, logs, cache, exports, and backups persist on the NAS.

## Plex LAN classification

Plex `LAN Networks` includes both local client subnets used during setup:

```text
192.168.10.0/24,192.168.2.0/24
```

This corrected an Apple TV at `192.168.2.218` being reported as WAN in Tautulli. Do not add the second subnet to Plex's unauthenticated-access list merely for LAN classification.

## Verify

```bash
docker ps --filter name=tautulli
docker inspect tautulli --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
docker exec tautulli getent hosts host.docker.internal
docker exec tautulli curl -v --connect-timeout 5 http://host.docker.internal:32400/identity
```

Expected Docker port output after hardening:

```text
tautulli    8181/tcp
```

There should be no `0.0.0.0:8182->8181` host mapping.

The Plex identity request should return `HTTP/1.1 200 OK`.

## Recovery

Recreate the container from `docker-compose.yml` and preserve `/volume1/docker/tautulli/config`. If the Plex connection fails, verify `host.docker.internal` resolution and port `32400` reachability from inside the container before changing Plex security settings.

## Deferred enhancements

- Add `taut.home` to Uptime Kuma.
- Configure selective Tautulli notifications for Plex downtime and undesirable transcodes.
