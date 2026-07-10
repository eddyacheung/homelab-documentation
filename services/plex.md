# Plex Media Server

[Existing content retained]

## Media Directory Permission Troubleshooting

### Symptoms

- Playback failed in both Plex and Infuse.
- Plex logged `boost::filesystem::status: Permission denied` while checking media files.
- Media files were present and readable from the host.

### Root Cause

The top-level media directory (`/volume2/Media`) was owned by `root:root` with `2770` permissions, preventing the Plex service account (UID 1001, GID 10 / admin) from traversing the directory during filesystem validation.

### Resolution

```bash
sudo chgrp admin /volume2/Media
sudo chmod 2770 /volume2/Media
docker restart plex
```

### Verification

```bash
docker exec -u 1001:10 plex ls -lh /media
```

Successful traversal confirms Plex has the required directory permissions.