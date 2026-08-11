# 2026-08-11 - Seerr Sharing and Tautulli Deployment

## Summary

Added a friend to the Plex/Seerr request workflow, reviewed Seerr request permissions, deployed Tautulli for Plex monitoring, corrected Plex LAN classification, and integrated Tautulli with the existing Pi-hole/Nginx Proxy Manager local-access pattern.

## Seerr user/request configuration

- Imported/used the friend's Plex identity for Seerr access.
- Enabled normal movie and series request permissions.
- Enabled auto-approval for non-4K requests.
- Reviewed Seerr's separate 4K request/auto-approve permissions.
- Confirmed the current media workflow does not require a separate Seerr 4K request path because Radarr/Sonarr quality profiles determine the eventual resolution and can prefer 4K with lower-quality fallback.
- Reviewed Seerr's Plex Watchlist auto-request permission. This remains optional because enabling it means items added to a user's Plex Watchlist can automatically become Seerr requests.
- Tautulli guest access was not granted to the friend; Tautulli remains an administrative monitoring interface.

## Tautulli deployment

Created persistent storage:

```text
/volume1/docker/tautulli/config
```

Matched existing media-service ownership:

```text
eddy.cheung:admin
UID 1001
GID 10
```

Initial deployment used the LinuxServer.io Tautulli image with `America/Chicago` timezone. Port `8181` could not be published directly because Nginx Proxy Manager already uses NAS port `8181` for its UI (`8181 -> 81`). Tautulli was temporarily published as `8182:8181` during setup.

## Plex connection troubleshooting

The setup wizard discovered several Docker bridge addresses for Plex and initially selected the NAS LAN address:

```text
192.168.10.101:32400
```

The wizard verification succeeded, but runtime calls from inside the Tautulli container timed out against that address. A direct test confirmed the failure:

```bash
docker exec tautulli curl -v --connect-timeout 5 http://192.168.10.101:32400/identity
```

A Docker bridge gateway test succeeded against `172.21.0.1:32400`, returning `HTTP/1.1 200 OK`, and Tautulli immediately refreshed Plex users/libraries and restored its websocket connection.

To avoid depending on a mutable `172.x` bridge address, Docker's host-gateway alias was added:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Docker Server version `29.4.3` resolved the alias successfully:

```text
host.docker.internal -> 172.17.0.1
```

A Plex identity request through the alias returned `HTTP/1.1 200 OK`. Tautulli's permanent Plex target was therefore changed to:

```text
host.docker.internal:32400
```

## Playback validation

Validated a live Apple TV/Infuse stream in Tautulli. The test session showed:

- Direct Play
- H.264 1080p video
- AAC stereo audio
- ASS subtitles
- No Plex transcoding

This confirmed live activity monitoring, stream details, bandwidth reporting, library statistics, recently-added data, and historical statistics were functioning.

## Plex LAN classification correction

The Apple TV client at `192.168.2.218` was initially classified as WAN because Plex `LAN Networks` only contained:

```text
192.168.10.0/24
```

Updated Plex `LAN Networks` to:

```text
192.168.10.0/24,192.168.2.0/24
```

After restarting playback, Tautulli correctly displayed the session as LAN. The Plex setting that allows networks to access the server without authentication was intentionally left unchanged; LAN classification does not require expanding unauthenticated access.

## Tautulli history and backups

- Activity logging ignore interval retained at 120 seconds.
- User playback history retained.
- Tautulli guest access kept disabled for normal Plex users.
- Automatic backup interval retained at 6 hours.
- Backup retention increased from 3 to 14 days.
- Backup path remains `/config/backups`, persisted through the NAS bind mount.

## Nginx Proxy Manager and Pi-hole

Confirmed both Prowlarr and Nginx Proxy Manager use the external Docker network `media-net`. Tautulli was attached to `media-net`, allowing NPM to proxy directly to the container by Docker DNS name.

NPM configuration:

```text
Domain: taut.home
Scheme: http
Forward hostname: tautulli
Forward port: 8181
Websockets: enabled
```

Pi-hole local DNS record:

```text
taut.home -> 192.168.10.101
```

Validated `http://taut.home` successfully through Pi-hole and NPM.

After proxy validation, the temporary host mapping `8182:8181` was removed. Final Docker port output is:

```text
tautulli    8181/tcp
```

This means Tautulli is no longer directly published on a NAS host port and is reached through NPM over `media-net`.

## Final architecture

```text
Browser
  -> Pi-hole local DNS (taut.home -> 192.168.10.101)
  -> Nginx Proxy Manager
  -> media-net
  -> tautulli:8181
  -> host.docker.internal:32400
  -> Plex
```

## Deferred follow-up

- Add Tautulli/`taut.home` monitoring to Uptime Kuma.
- Configure selective Tautulli notifications, focusing on Plex downtime and unwanted/expensive transcodes rather than start/stop notification noise.
