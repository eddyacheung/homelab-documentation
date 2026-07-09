# Unpackerr

Last updated: 2026-07-09

## Purpose
Unpackerr automatically extracts supported archive downloads and notifies Sonarr and Radarr so completed downloads can be imported without manual extraction.

## Deployment
- Deployed as its own Portainer Stack.
- Attached to the existing `media-net` Docker network.
- Mounted `/volume2/Media` as `/data`.
- Mounted `/volume1/docker/unpackerr/config` as `/config`.

## Configuration
- Sonarr: `http://sonarr:8989`
- Radarr: `http://radarr:7878`
- Watch folder: `/data/downloads`
- Polling enabled in addition to filesystem notifications.

## Troubleshooting
### Config permissions
Initially the container could not create `/config/unpackerr.conf` or `unpackerr.log` due to permissions. Fixed by changing ownership of `/volume1/docker/unpackerr` to UID/GID 1000 and granting write access.

### Media permissions
The media library is owned by `root` with restrictive permissions. Sonarr, Radarr, and qBittorrent already run as `root`, while Unpackerr was initially configured as `1000:1000`, preventing access to `/data`.

Resolution:
- Removed `user: 1000:1000` from the compose file.
- Redeployed Unpackerr running as root to match the existing media stack.

## Validation
Verified:
- Configuration file created successfully.
- Connected to Sonarr.
- Connected to Radarr.
- Watching `/data/downloads`.
- Able to browse the `/data` mount.

## Rollback
- Stop and remove the Unpackerr stack.
- No changes are made to Sonarr or Radarr configuration by removing the container.
- Restore the previous compose file if needed.

## Next Steps
- Validate extraction with a real archived download.
- Confirm Sonarr or Radarr imports automatically after extraction.
- Consider reorganizing the downloads directory to contain only active download content.
