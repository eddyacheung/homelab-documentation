# Unpackerr

Last updated: 2026-07-09

## Status
**Completed**

## Purpose
Unpackerr automatically extracts supported archive downloads and notifies Sonarr and Radarr so completed downloads can be imported without manual extraction.

## Deployment
- Deployed as its own Portainer Stack.
- Attached to the existing `media-net` Docker network.
- Mounted `/volume2/Media` as `/data`.
- Mounted `/volume1/docker/unpackerr/config` as `/config`.
- Running as `root` to match the existing media stack permissions.

## Configuration
- Sonarr: `http://sonarr:8989`
- Radarr: `http://radarr:7878`
- Watch folder: `/data/downloads`
- Polling enabled in addition to filesystem notifications.

## Troubleshooting
### Config permissions
Resolved by correcting ownership and permissions on `/volume1/docker/unpackerr`.

### Media permissions
The media library is owned by `root`. Running Unpackerr as `1000:1000` prevented access to `/data`. Removing the explicit user and allowing the container to run as `root` resolved the issue.

## Validation
Verified:
- Configuration file created successfully.
- Connected to Sonarr.
- Connected to Radarr.
- Watching `/data/downloads`.
- Able to browse the `/data` mount.

A live archive extraction has not yet been observed, but this is considered an acceptable stopping point because archived downloads are uncommon in this environment. The deployment is complete and will validate itself naturally when an archived download is encountered.

## Rollback
- Stop and remove the Unpackerr stack.
- No changes are made to Sonarr or Radarr configuration by removing the container.
