# Homelab Backup and Disaster Recovery

Date implemented: 2026-07-23

## Summary

The UGREEN NAS now performs a verified nightly backup to a dedicated 2 TB Seagate USB drive. The system protects Docker configuration, selected application state, Portainer Compose definitions, and PostgreSQL databases while excluding replaceable media, downloads, caches, transcodes, Docker images, and writable container layers.

The backup workflow uses standard Linux tools so recovery does not depend on a proprietary backup application.

## Storage

| Item | Value |
|---|---|
| Backup device | Dedicated USB external drive |
| Device at implementation | `/dev/sdc1` |
| Filesystem | ext4 |
| Label | `HomelabBackup` |
| UUID | `1dea3c33-dd86-4648-b177-d13678231c73` |
| Mount point | `/backup` |
| Capacity | approximately 1.8 TB usable |
| Initial backup usage | approximately 2.0 GB |

The scripts refuse to run unless `/backup` is an active mount point. This prevents an unplugged USB drive from causing backups to be written silently to the NAS system disk.

## Schedule

A systemd timer runs the complete backup every night at 03:00 Central time.

```text
homelab-backup.timer -> homelab-backup.service -> /opt/homelab-backup/backup-all.sh
```

The timer uses `Persistent=false`. If the NAS is powered off at 03:00, systemd does not launch a disruptive catch-up run after the NAS starts during the day.

## Backup workflow

The master script obtains an exclusive `flock` lock and runs three stages:

1. Static configuration archive
2. PostgreSQL database dumps
3. Cold archives of stateful Docker services
4. Retention cleanup and summary logging

The first validated end-to-end run completed in 1 minute 2 seconds.

## Directory layout

```text
/backup/
├── compose/       Static configuration and Portainer Compose archives
├── databases/     PostgreSQL custom-format dumps
│   ├── seerr/
│   └── teslamate/
├── docker/        Per-service stateful archives
├── logs/          Stage and master logs
├── restore/       Reserved restore workspace
├── git/           Reserved repository-backup location
├── homeassistant/ Reserved for future native HA backup exports
└── teslamate/     Reserved for future auxiliary TeslaMate exports
```

## Static configuration coverage

The static archive includes:

- Eufy Security WS persistent data
- go2rtc configuration
- Nginx Proxy Manager Let's Encrypt certificates
- Pi-hole dnsmasq configuration
- Recyclarr configuration
- Unpackerr configuration
- Watchtower files
- Portainer Compose definitions
- Portainer Compose archive

Static source list:

```text
volume1/docker/eufy-security-ws/data
volume1/docker/go2rtc/config
volume1/docker/nginx-proxy-manager/letsencrypt
volume1/docker/pihole/etc-dnsmasq.d
volume1/docker/recyclarr/config
volume1/docker/unpackerr/config
volume1/docker/watchtower
volume1/docker/portainer/compose
volume1/docker/portainer/compose-archive
```

Static archives use GNU `tar` streamed through Zstandard level 6 and are stored as `tar.zst` files.

## PostgreSQL coverage

PostgreSQL backups are created online with the matching client inside each database container.

| Application | Container | Database | User | PostgreSQL version at implementation |
|---|---|---|---|---|
| Seerr | `Seerr-DB` | `seerr` | `seerruser` | 16.14 |
| TeslaMate | `teslamate-database` | `teslamate` | `teslamate` | 18.4 |

Each database uses `pg_dump --format=custom --no-owner --no-acl`. The dump is validated with `pg_restore --list` before it is accepted.

## Stateful Docker coverage

Each listed container is stopped individually, archived, validated, and restarted before the script proceeds to the next service.

| Service | Container | Source path |
|---|---|---|
| Home Assistant | `homeassistant` | `/volume1/docker/homeassistant/config` |
| Sonarr | `sonarr` | `/volume1/docker/sonarr/config` |
| Radarr | `radarr` | `/volume1/docker/radarr/config` |
| Prowlarr | `prowlarr` | `/volume1/docker/prowlarr/config` |
| qBittorrent | `qbittorrent` | `/volume1/docker/qbittorrent/config` |
| Uptime Kuma | `uptime-kuma` | `/volume1/docker/uptime-kuma` |
| Nginx Proxy Manager | `nginx-proxy-manager` | `/volume1/docker/nginx-proxy-manager/data` |
| Portainer | `portainer` | `/volume1/docker/portainer` |
| Homarr | `Homarr` | `/volume1/docker/homarr` |

A trap attempts to restart the current container if the script is interrupted or fails while that service is stopped.

## Deliberate exclusions

The system does not back up:

- `/volume2/Media`
- Movies and television libraries
- Downloads
- Plex transcode data
- Docker images
- Docker overlay storage
- Writable container layers
- Replaceable caches
- Screenshots
- Abandoned `seerr/db-broken` data

Plex application metadata is not included in version 1. Plex media remains outside the backup scope because of its size.

## Integrity controls

Every `tar.zst` archive is checked with:

```bash
zstd --test archive.tar.zst
tar --use-compress-program=zstd --list --file=archive.tar.zst
```

Every accepted archive and PostgreSQL dump receives a SHA-256 sidecar file. Verification example:

```bash
sha256sum -c archive.tar.zst.sha256
```

PostgreSQL custom-format dumps are additionally checked with `pg_restore --list`.

## Retention

| Data | Retention |
|---|---|
| Backup archives and database dumps | 30 days |
| Logs | 90 days |
| Incomplete `.partial` files | Removed after 1 day |

The current policy is simple rolling daily retention. Weekly and monthly retention tiers are not implemented in version 1.

## Logs and status

Master logs are written to:

```text
/backup/logs/full-backup-YYYY-MM-DD_HHMMSS.log
```

A successful run ends with:

```text
FULL BACKUP COMPLETED SUCCESSFULLY
```

Useful checks:

```bash
systemctl status homelab-backup.timer --no-pager
systemctl list-timers homelab-backup.timer --all
systemctl status homelab-backup.service --no-pager
journalctl -u homelab-backup.service --since today --no-pager
tail -n 40 "$(ls -1t /backup/logs/full-backup-*.log | head -n 1)"
```

## Restore procedures

### Verify before restoring

Always validate the checksum before extracting or importing:

```bash
sha256sum -c BACKUP_FILE.sha256
```

### Test-extract a configuration archive

Use a temporary destination first. Archive paths are relative to `/` and include `volume1/...`.

```bash
mkdir -p /backup/restore/test
cd /backup/restore/test

tar --use-compress-program=zstd \
  --extract \
  --file=/backup/docker/homeassistant/homeassistant-YYYY-MM-DD_HHMMSS.tar.zst
```

Inspect the restored files under:

```text
/backup/restore/test/volume1/docker/homeassistant/config
```

### Restore a stateful Docker service

1. Stop the affected container.
2. Preserve or rename the current source directory.
3. Verify the chosen archive checksum.
4. Extract the archive from `/` or into a temporary directory and copy the data into place.
5. Confirm ownership and permissions match the original service.
6. Start the container.
7. Review service logs and application health.

Example direct extraction after preserving the existing folder:

```bash
docker stop homeassistant
mv /volume1/docker/homeassistant/config /volume1/docker/homeassistant/config.pre-restore

tar --use-compress-program=zstd \
  --extract \
  --directory=/ \
  --file=/backup/docker/homeassistant/homeassistant-YYYY-MM-DD_HHMMSS.tar.zst

docker start homeassistant
```

Do not delete the pre-restore directory until the restored service has been validated.

### Restore Seerr PostgreSQL

Use a clean target database. Exact container recreation may vary with the current Compose definition.

```bash
docker exec -i Seerr-DB dropdb --username=seerruser --if-exists seerr
docker exec -i Seerr-DB createdb --username=seerruser seerr

docker exec -i Seerr-DB pg_restore \
  --username=seerruser \
  --dbname=seerr \
  --no-owner \
  --no-acl \
  --clean \
  --if-exists \
  < /backup/databases/seerr/seerr-YYYY-MM-DD_HHMMSS.dump
```

Stop the Seerr application container before replacing its database, then restart it after the restore.

### Restore TeslaMate PostgreSQL

Stop TeslaMate before replacing its database:

```bash
docker stop teslamate

docker exec -i teslamate-database dropdb --username=teslamate --if-exists teslamate
docker exec -i teslamate-database createdb --username=teslamate teslamate

docker exec -i teslamate-database pg_restore \
  --username=teslamate \
  --dbname=teslamate \
  --no-owner \
  --no-acl \
  --clean \
  --if-exists \
  < /backup/databases/teslamate/teslamate-YYYY-MM-DD_HHMMSS.dump

docker start teslamate
```

Review TeslaMate and PostgreSQL logs after the restore.

## Full NAS recovery outline

1. Restore or reinstall the NAS operating system.
2. Install Docker and Portainer.
3. Mount the USB backup drive read-only initially when practical.
4. Retrieve the version-controlled Compose definitions from GitHub.
5. Recreate required Docker networks and directory structure.
6. Deploy database containers first.
7. Restore Seerr and TeslaMate PostgreSQL dumps.
8. Restore application configuration archives.
9. Deploy remaining Compose stacks.
10. Validate DNS, reverse proxy, Home Assistant, media automation, TeslaMate, monitoring, and remote access.
11. Re-enable the backup timer only after `/backup` is mounted correctly.

## Validation completed

The implementation was validated by:

- Confirming `/backup` is mounted from `/dev/sdc1` as ext4
- Completing the static archive and inspecting its file list
- Validating all SHA-256 checksums
- Creating and validating Seerr and TeslaMate custom-format dumps
- Cold-archiving all nine stateful services
- Confirming all nine containers returned to `running`
- Completing a full master run successfully
- Enabling the systemd timer and confirming its next trigger

## Known follow-ups

- Verify the first unattended 03:00 run.
- Perform a restore extraction into `/backup/restore`.
- Perform a non-production PostgreSQL restore test when a suitable temporary database environment is available.
- Add Home Assistant dashboard visibility for last success, duration, backup age, and free space.
- Decide whether Plex metadata warrants a separate lower-frequency backup.
- Add a direct backup of the local Git checkout only if it provides value beyond GitHub as the source of truth.
