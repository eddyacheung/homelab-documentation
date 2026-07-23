# Homelab Backup System Completion

Date: 2026-07-23

## Summary

Implemented a native Linux backup and disaster-recovery system for the UGREEN DXP4800 Plus using a dedicated 2 TB Seagate USB drive.

## Storage preparation

- Erased the previous NTFS contents after confirming they were no longer needed.
- Reformatted the drive as ext4.
- Assigned label `HomelabBackup`.
- Mounted the drive at `/backup`.
- Confirmed systemd reports `backup.mount` as active.
- Added mount-point safety checks to prevent writes to the NAS system disk if the USB drive is absent.

## Backup components

Created scripts under `/opt/homelab-backup`:

- `backup-static.sh`
- `backup-databases.sh`
- `backup-stateful.sh`
- `backup-all.sh`
- `static-paths.txt`

## Protected data

- Static Docker configuration and Portainer Compose definitions
- Seerr PostgreSQL database
- TeslaMate PostgreSQL database
- Home Assistant
- Sonarr
- Radarr
- Prowlarr
- qBittorrent
- Uptime Kuma
- Nginx Proxy Manager
- Portainer
- Homarr

Media libraries, downloads, Docker images, overlay storage, caches, screenshots, and Plex transcode data are deliberately excluded.

## Reliability controls

- GNU tar plus Zstandard level 6 compression
- PostgreSQL custom-format dumps
- `pg_restore --list` database validation
- `zstd --test` archive validation
- tar listing validation
- SHA-256 sidecar checksums
- Exclusive `flock` lock
- Recovery trap that restarts a service if a stateful backup fails while its container is stopped
- Individual stop, archive, validation, and restart for stateful services
- Centralized logs

## Retention

- Backup archives and database dumps: 30 days
- Logs: 90 days
- Incomplete `.partial` files: removed after one day

## Automation

Created and enabled:

```text
/etc/systemd/system/homelab-backup.service
/etc/systemd/system/homelab-backup.timer
```

Schedule:

```text
Daily at 03:00 Central
```

The timer uses `Persistent=false` so a missed overnight run does not automatically interrupt services during daytime startup.

## Validation

- Static archive created, checksum verified, and contents inspected.
- Seerr and TeslaMate dumps created and validated.
- All nine stateful service archives passed SHA-256 verification.
- All stopped containers returned to `running`.
- Full end-to-end backup completed successfully in 1 minute 2 seconds.
- Initial backup footprint was approximately 2.0 GB.
- Timer was enabled and confirmed waiting for the first unattended 03:00 run.

## Result

The homelab now has an automated, validated, low-cost local backup system and a documented recovery path. See `services/homelab-backup-and-disaster-recovery.md` for architecture, coverage, validation, maintenance, and restore procedures.
