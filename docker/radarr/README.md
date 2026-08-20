# Radarr

## Purpose

Automates movie monitoring, acquisition, importing, and library organization.

## Deployment

- Container: `radarr`
- Image: `ghcr.io/linuxserver/radarr:latest`
- Published port: `7878:7878`
- Network: external `media-net`
- Config: `/volume1/docker/radarr/config:/config`
- Media: `/volume2/Media:/data`

## Automated storage downsizing

A custom autonomous Radarr downsizer runs on the NAS to replace oversized 2160p movies with smaller, efficient 2160p encodes when conservative safety rules are satisfied.

Current production version: **v8.2**.

Key behavior:

- One active replacement at a time.
- Minimum existing file size: 25 GiB.
- Minimum savings: 30%.
- Minimum torrent seeders: 2.
- 2160p-only replacement candidates.
- Edition/cut mismatch protection.
- Safe handling of Radarr's `Existing file meets cutoff` condition.
- Manual-import finisher for completed downloads that Radarr considers a non-upgrade.
- Verification before reclaimed storage is counted.
- Discord reporting to `#automation-alerts` for successful replacements, attention conditions, and errors.
- Root cron invokes the orchestration wrapper every 30 minutes.

Radarr's application recycle bin is disabled so space from successfully replaced media is reclaimed immediately.

See [downsizer.md](downsizer.md) for the full workflow, safety policy, scheduled command, logs, state files, and notification configuration.

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=radarr
docker logs --tail 100 radarr
curl -I http://127.0.0.1:7878
```

Back up the config directory before rebuilding. Preserve the shared `/data` path because it supports hardlinks and consistent download-client paths.