# Media Library Recovery and SMB Share Restoration

**Date:** 2026-07-27  
**System:** UGREEN DXP4800 Plus NAS  
**Canonical media path:** `/volume2/media`

## Summary

The media storage layout was standardized from the mixed-case path `/volume2/Media` to the lowercase path `/volume2/media`. During the case-only rename, the destination directory already existed, so the original media library was moved into a nested directory at `/volume2/media/media-temp` instead of becoming the contents of `/volume2/media`.

Docker bind mounts had already been changed to `/volume2/media`, which made the media library appear missing even though approximately 15 TB of data was still present on disk. At the same time, the UGOS-managed Samba configuration no longer exposed the `Media` share to Windows.

The library was recovered without copying or restoring the media data. The nested directory was flattened, the SMB share was restored, all active Docker bind mounts were updated to lowercase paths, and the media stack was validated.

## Objective

Standardize the media storage path from:

```text
/volume2/Media
```

to:

```text
/volume2/media
```

This established one case-consistent path across Linux, Docker Compose, qBittorrent, Plex, Radarr, Sonarr, Prowlarr, Unpackerr, and Windows SMB access.

## Initial Symptoms

- Both `Downloads` and `downloads` directories existed.
- The Windows `Media` SMB share disappeared.
- Docker containers started, but media access was inconsistent or appeared empty.
- Windows Explorer showed only the remaining NAS shares.
- Docker Compose files and live mounts contained a mixture of `/volume2/Media` and `/volume2/media` references.

## Root Cause

Linux treats `Media` and `media`, as well as `Downloads` and `downloads`, as different paths.

The rename used an intermediate directory:

```bash
mv /volume2/Media /volume2/media-temp
mv /volume2/media-temp /volume2/media
```

Because `/volume2/media` already existed, the second command moved the original library inside that directory rather than replacing it. The real media tree therefore ended up here:

```text
/volume2/media/media-temp
```

Meanwhile, active Docker configuration had been updated to mount:

```text
/volume2/media
```

The containers were therefore looking one directory above the real library. Separately, UGOS removed or failed to preserve the Samba share definition for the renamed directory.

## Investigation

### Identify duplicate paths

```bash
find /volume1 /volume2 -maxdepth 4 -type d \
  \( -name Downloads -o -name downloads -o -name Media -o -name media \) \
  -print
```

### Inspect ownership, permissions, and usage

```bash
ls -ld /volume2/Media /volume2/media 2>/dev/null
du -sh /volume2/Media /volume2/media 2>/dev/null
find /volume2 -maxdepth 2 -type d | sort
```

### Identify open SMB handles

```bash
lsof +D /volume2/Media 2>/dev/null | head -50
smbstatus
```

The open handles belonged to `smbd`, confirming that a Windows SMB client had the old share open.

### Find configuration references

```bash
command grep --binary-files=without-match -RFn \
  '/volume2/Media' \
  /volume1/docker \
  /etc \
  /root \
  2>/dev/null
```

Active references were found in Portainer Compose stacks, the standalone qBittorrent Compose file, and MiniDLNA configuration. Historical backups, Open WebUI uploads, and documentation copies were inert and could not recreate directories.

### Locate the real library

Filesystem inspection showed the complete library under:

```text
/volume2/media/media-temp
```

This confirmed that the data had not been deleted and that a large copy or backup restore was unnecessary.

## Recovery Procedure

### 1. Stop media services and disconnect SMB clients

Close Windows Explorer windows and mapped-drive sessions that are accessing the NAS. Stop media containers before changing paths so no application writes during the repair.

Example:

```bash
docker stop qbittorrent sonarr radarr plex prowlarr unpackerr
```

Confirm no active SMB sessions remain:

```bash
smbstatus
```

### 2. Preserve placeholder directories

The lowercase destination contained newly created placeholder directories. These were moved aside before restoring the real tree:

```bash
mkdir -p /root/media-layout-backup
mv /volume2/media/movies /root/media-layout-backup/ 2>/dev/null || true
mv /volume2/media/tv /root/media-layout-backup/ 2>/dev/null || true
mv /volume2/media/downloads /root/media-layout-backup/ 2>/dev/null || true
```

### 3. Flatten the nested media library

Move the real library contents into the canonical directory:

```bash
mv /volume2/media/media-temp/* /volume2/media/
```

Inspect for hidden entries before removing the temporary directory:

```bash
find /volume2/media/media-temp -mindepth 1 -maxdepth 1 -print
```

When empty:

```bash
rmdir /volume2/media/media-temp
```

### 4. Update Docker Compose bind mounts

The affected Portainer stack files were backed up before replacement:

```bash
for stack in 6 18 34 47 49 50; do
  cp -a \
    "/volume1/docker/portainer/compose/$stack/docker-compose.yml" \
    "/volume1/docker/portainer/compose/$stack/docker-compose.yml.bak-20260727"
done
```

Replace the old source path:

```bash
for stack in 6 18 34 47 49 50; do
  sed -i 's#/volume2/Media#/volume2/media#g' \
    "/volume1/docker/portainer/compose/$stack/docker-compose.yml"
done
```

The standalone qBittorrent Compose file also required correction:

```bash
cp -a \
  /volume1/docker/qbittorrent/docker-compose.yml \
  /volume1/docker/qbittorrent/docker-compose.yml.bak-20260727-lowercase

sed -i 's#/volume2/Media#/volume2/media#g' \
  /volume1/docker/qbittorrent/docker-compose.yml
```

Validate all affected Compose files before recreation:

```bash
for stack in 6 18 34 47 49 50; do
  echo "===== Stack $stack ====="
  docker compose \
    -f "/volume1/docker/portainer/compose/$stack/docker-compose.yml" \
    config --quiet \
    && echo VALID \
    || echo INVALID
done
```

Recreate the affected stacks only after every file validates:

```bash
for stack in 6 18 34 47 49 50; do
  docker compose \
    -f "/volume1/docker/portainer/compose/$stack/docker-compose.yml" \
    up -d --force-recreate
done
```

### 5. Restore the SMB share

`testparm -s` showed that the `Media` share was no longer defined. The share was restored by adding the following definition to `/etc/samba/smbshare.conf`:

```ini
[Media]
path=/volume2/media
```

Reload Samba:

```bash
smbcontrol all reload-config
```

Validate the effective share configuration:

```bash
testparm -s 2>/dev/null | grep -A8 '^\[Media\]'
```

The share name can remain `Media`; the underlying Linux path is lowercase and independent of the SMB display name.

### 6. Restart and validate the media stack

Restart the affected services, including:

- Gluetun
- qBittorrent
- Plex
- Radarr
- Sonarr
- Prowlarr
- Unpackerr

Inspect live mounts:

```bash
docker inspect radarr prowlarr sonarr gluetun qbittorrent plex unpackerr \
  --format '{{.Name}}{{range .Mounts}}{{printf "\n  %s -> %s" .Source .Destination}}{{end}}'
```

Check specifically for stale uppercase paths:

```bash
docker inspect radarr prowlarr sonarr gluetun qbittorrent plex unpackerr \
  --format '{{range .Mounts}}{{println .Source}}{{end}}' \
  | command grep -F '/volume2/Media'
```

No output is the expected result.

## Final Container Mounts

The validated live mounts were:

| Service | Host path | Container path |
|---|---|---|
| Radarr | `/volume2/media` | `/data` |
| Sonarr | `/volume2/media` | `/data` |
| qBittorrent | `/volume2/media` | `/data` |
| Plex | `/volume2/media` | `/media` |
| Unpackerr | `/volume2/media` | `/data` |
| Prowlarr | `/volume2/media/downloads` | `/downloads` |
| Prowlarr | `/volume2/media/tv` | `/tv` |
| Prowlarr | `/volume2/media/movies` | `/movies` |
| Gluetun | No media bind mount | Expected |

## Final Filesystem Layout

```text
/volume2/media
├── animated
├── anime
├── audio
├── downloads
├── met
├── movies
├── recyclebin
├── #recycle
├── transcode
└── tv
```

## Validation Results

- SMB `Media` share accessible from Windows.
- Plex healthy and able to see its libraries.
- Gluetun healthy.
- Radarr healthy.
- Sonarr operational.
- qBittorrent operational.
- Prowlarr and Unpackerr operational.
- All active Docker bind mounts use `/volume2/media`.
- No active references remain to `/volume2/Media`.
- No active references remain to `/volume2/media/media-temp`.
- Approximately 15 TB of media recovered without copying the library or restoring a backup.

## Outstanding Persistence Check

The restored SMB definition was manually added to:

```text
/etc/samba/smbshare.conf
```

UGOS appears to generate or manage this file. The share should therefore be tested after a controlled NAS reboot and after future UGOS firmware or shared-folder changes.

Post-reboot validation:

```text
\\192.168.10.101\Media
```

Also confirm that Docker containers start and that Plex, Radarr, Sonarr, and qBittorrent still access `/volume2/media`.

If the share disappears, identify the persistent UGOS share database or register the directory through the UGOS shared-folder interface instead of relying on the generated Samba file.

## Lessons Learned

1. Linux paths are case-sensitive; standardize path capitalization before deploying services.
2. Before a case-only rename, verify that the lowercase destination does not already exist.
3. Use an intermediate name for case-only renames, but inspect the destination immediately afterward.
4. Validate directory structure with `find`, `ls`, and `du` before assuming data loss.
5. Docker bind mounts can be correct while the underlying library is nested at the wrong level.
6. Filesystem availability and SMB share availability must be tested independently.
7. Verify effective live mounts with `docker inspect`; Compose files alone are not proof of runtime state.
8. Back up Compose files before bulk path replacement.
9. Historical backups and uploaded documentation may contain obsolete paths without affecting running services.
10. Avoid copying multi-terabyte libraries until the actual directory topology is understood.