# UGOS Shared Folder Visibility and USB Mount Refresh

Date resolved: 2026-07-28

## Summary

The UGREEN NAS web File Manager temporarily failed to display two otherwise healthy storage locations:

- the external `HomelabBackup` USB drive, which initially showed **Access denied**
- the `media` shared folder under `/volume2/media`, which temporarily disappeared from the web File Manager

The underlying Linux filesystem, Samba configuration, Docker access, and backup workflow remained healthy. The evidence indicates a stale UGOS metadata or web UI state rather than filesystem corruption or an invalid Samba share.

## Environment

- NAS: UGREEN DXP4800 Plus
- Operating system: UGOS Pro
- Media path: `/volume2/media`
- USB mount managed by UGOS: `/mnt/@usb/sdc1`
- Stable backup path used by scripts: `/backup`

## Symptoms

### External USB backup drive

The UGOS File Manager showed the external drive under **Peripheral** but returned **Access denied** when opened.

Linux still mounted the drive correctly, the backup files remained present, and the backup service continued to operate.

### Media shared folder

The `media` share was temporarily absent from the UGOS File Manager even though:

- `/volume2/media` existed
- the expected media subdirectories were present
- Docker services continued to use the path
- Samba still contained a valid `[media]` share

## Validation performed

### Confirm the media directory exists

```bash
find /volume2 -maxdepth 3 \( -iname Movies -o -iname "TV Shows" -o -iname Anime -o -iname "Animated Movies" \)
```

The search confirmed that the active path is lowercase:

```text
/volume2/media
```

Older references to `/volume2/Media` were stale and should not be used.

### Confirm the Samba share exists

```bash
grep -A20 '^\[media\]' /etc/samba/smbshare.conf
```

The share was present and pointed to:

```text
/volume2/media
```

### Validate the effective Samba configuration

```bash
testparm -s | sed -n '/^\[media\]/,/^\[/p'
```

`testparm` loaded the configuration successfully and showed the expected path, user access, browseability, write access, recycle-bin settings, and VFS modules.

### Confirm the USB and backup mounts

```bash
findmnt /mnt/@usb/sdc1
findmnt /backup
```

UGOS mounted the physical USB filesystem at `/mnt/@usb/sdc1`. A bind mount presents that storage at `/backup` for the backup scripts.

The active `/etc/fstab` entry is:

```fstab
/mnt/@usb/sdc1  /backup  none  bind,nofail,x-systemd.requires-mounts-for=/mnt/@usb/sdc1  0  0
```

## Resolution

The external USB drive was unplugged and reconnected, allowing UGOS to remount it and refresh its storage state. After allowing time for UGOS to refresh, both the USB drive and the `media` shared folder became visible again in the web File Manager.

No Samba edits, filesystem repairs, permission changes, or media-share recreation were required.

Opening the hidden shared-folder administration screen may also have prompted UGOS to refresh its internal share metadata:

1. Open **Files**.
2. Select the small tools or settings icon in the upper-right corner.
3. Open **Shared folder management**.

This is also the correct location for deleting a registered shared folder. Deleting only its directory from the shell can leave stale UGOS or Samba metadata behind.

## Root cause assessment

The most likely cause was stale UGOS storage or shared-folder metadata in the web application layer.

The lower layers remained healthy throughout the incident:

| Layer | Result |
|---|---|
| Linux filesystem | Healthy |
| Samba configuration | Healthy |
| Docker bind-mount access | Healthy |
| Backup service and timer | Healthy |
| UGOS File Manager display | Temporarily stale |

Because the folder returned without configuration changes, the issue should be treated as a UI or metadata synchronization problem rather than proof of disk, filesystem, or Samba failure.

## Recommended troubleshooting order

When a shared folder disappears from the UGOS File Manager:

1. Verify the directory exists with `ls`, `find`, or `stat`.
2. Confirm the expected capitalization of the path.
3. Check `/etc/samba/smbshare.conf` for the registered share.
4. Validate the effective Samba configuration with `testparm -s`.
5. Check **Files > tools/settings > Shared folder management**.
6. Confirm dependent Docker containers can still access the path.
7. For removable storage, safely disconnect and reconnect the drive.
8. Allow UGOS several minutes to refresh, or reboot during a maintenance window.
9. Recreate or manually edit a share only after the non-destructive checks fail.

## Lessons learned

UGOS has multiple layers that can temporarily drift out of sync:

1. Linux filesystem
2. Samba share configuration
3. UGOS internal storage and shared-folder metadata
4. Web File Manager presentation

A missing entry in the web File Manager does not necessarily mean the underlying data or share is missing. Validate the lower layers before making destructive changes.
