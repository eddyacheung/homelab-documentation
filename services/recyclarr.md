# Recyclarr

## Purpose

Recyclarr is used to manage and synchronize Sonarr and Radarr quality profiles, custom formats, and TRaSH Guides recommendations. The goal is to make media quality configuration easier to maintain over time instead of manually rebuilding profiles in each application.

This project is being implemented in short sessions to avoid risky profile changes.

Last updated: **2026-07-09**

## Current Status

Status: **In Progress**

Recyclarr is deployed and has been configured enough to maintain local configuration files. The current safe operating posture is to keep only the intended active config in `/config/configs` and move disabled or experimental configs into `/config/configs-disabled`.

Latest verified config state on the NAS:

```text
/volume1/docker/recyclarr/config/configs:
uhd-bluray-web.yml

/volume1/docker/recyclarr/config/configs-disabled:
remux-2160p-combined.yml
```

Important safety note: before making further Recyclarr changes, confirm whether a real `sync` has already been run. Earlier sessions were preview/staging-focused, but this document should not assume Sonarr or Radarr are unchanged unless the current app state has been checked.

## Session Summary

### Session 1 Completed

- Deployed Recyclarr as a dedicated Portainer Stack.
- Confirmed the container is running.
- Attached Recyclarr to the existing `media-net` Docker network.
- Created and initialized the Recyclarr configuration directory.
- Fixed container volume permissions.
- Confirmed Recyclarr can initialize the official resource providers for TRaSH Guides and config templates.
- No Sonarr or Radarr changes were applied during this initial deployment session.

### Session 2 Completed

- Reviewed Recyclarr v8 CLI behavior while attempting to move from deployment into template-based configuration.
- Confirmed the Recyclarr v8 CLI does not support the older/example `--raw` flag for template listing.
- Confirmed `recyclarr config create -t TEMPLATE_NAME` initializes the official providers but does not create a usable config when `TEMPLATE_NAME` is only a placeholder.
- Confirmed the local template workflow needs the actual template identifier before a real config can be generated.
- Stopped before applying any templates or syncing changes into Sonarr or Radarr.
- No Sonarr or Radarr changes were applied during this session.

### 2026-07-09 Config Cleanup Completed

The combined Remux config was disabled by moving it out of the active Recyclarr configs directory:

```powershell
ssh ugreen "sudo mv /volume1/docker/recyclarr/config/configs/remux-2160p-combined.yml /volume1/docker/recyclarr/config/configs-disabled/remux-2160p-combined.yml"
```

The active and disabled config directories were then checked:

```powershell
ssh ugreen "sudo ls -la /volume1/docker/recyclarr/config/configs /volume1/docker/recyclarr/config/configs-disabled"
```

Observed active config directory:

```text
/volume1/docker/recyclarr/config/configs:
total 16
drwxr-xr-x 1 1000 1000   62 Jul  9 17:55 .
drwxrwx--- 1 1000 1000  154 Jul  4 10:07 ..
-rw-r--r-- 1 1000 1000 6210 Jul  4 10:09 uhd-bluray-web.yml
```

Current active config:

```text
uhd-bluray-web.yml
```

Current disabled config:

```text
remux-2160p-combined.yml
```

Reason for disabling `remux-2160p-combined.yml`:

- Keeps the active Recyclarr config set smaller and easier to reason about.
- Avoids syncing an extra 2160p Remux-oriented config while the setup is still being tuned.
- Preserves the config for later review instead of deleting it.
- Makes rollback simple by moving the file back into `/configs`.

## Deployment

Recyclarr was deployed as its own Portainer Stack instead of being combined with Sonarr or Radarr.

Reasoning:

- Keeps rollback simple.
- Keeps service ownership clean.
- Avoids unnecessary changes to stable Sonarr and Radarr stacks.
- Matches the existing homelab documentation style of one major service per page.

## Docker Stack

```yaml
services:
  recyclarr:
    image: ghcr.io/recyclarr/recyclarr:8
    container_name: recyclarr
    user: 1000:1000
    restart: unless-stopped
    environment:
      - TZ=America/Chicago
    volumes:
      - /volume1/docker/recyclarr/config:/config
    networks:
      - media-net

networks:
  media-net:
    external: true
```

## Network

Recyclarr is attached to:

```text
media-net
```

Sonarr and Radarr are also attached to `media-net`, so Recyclarr should be able to reach them by container name:

```text
http://sonarr:8989
http://radarr:7878
```

## Directory Layout

Host path:

```text
/volume1/docker/recyclarr/config
```

Container path:

```text
/config
```

Observed initialized directories:

```text
/config/configs
/config/configs-disabled
/config/includes
/config/logs
/config/resources
/config/state
/config/settings.yml
```

Active config directory:

```text
/volume1/docker/recyclarr/config/configs
```

Disabled config directory:

```text
/volume1/docker/recyclarr/config/configs-disabled
```

## Commands Used

Create config directory:

```bash
mkdir -p /volume1/docker/recyclarr/config
```

Check container:

```bash
docker ps --filter name=recyclarr
docker logs recyclarr --tail=50
```

Initial config creation command attempted:

```bash
docker exec recyclarr recyclarr create-config
```

This failed because the old command format is no longer valid in Recyclarr v8.

Correct v8 command used:

```bash
docker exec recyclarr recyclarr config create
```

List local configs:

```bash
docker exec recyclarr recyclarr config list local
```

List templates:

```bash
docker exec recyclarr recyclarr config list templates
```

Inspect config files from inside the container:

```bash
docker exec recyclarr find /config -maxdepth 3 -type f -print
docker exec recyclarr ls -la /config /config/configs
docker exec recyclarr cat /config/configs/recyclarr.yml
```

Disable a config without deleting it:

```bash
sudo mkdir -p /volume1/docker/recyclarr/config/configs-disabled
sudo mv /volume1/docker/recyclarr/config/configs/remux-2160p-combined.yml /volume1/docker/recyclarr/config/configs-disabled/remux-2160p-combined.yml
```

From Windows PowerShell over SSH:

```powershell
ssh ugreen "sudo mv /volume1/docker/recyclarr/config/configs/remux-2160p-combined.yml /volume1/docker/recyclarr/config/configs-disabled/remux-2160p-combined.yml"
ssh ugreen "sudo ls -la /volume1/docker/recyclarr/config/configs /volume1/docker/recyclarr/config/configs-disabled"
```

## Session 2 Commands and Findings

Template creation was tested with a placeholder name:

```bash
docker exec recyclarr recyclarr config create -t TEMPLATE_NAME
```

Observed output:

```text
[INF] Initializing provider: official (type: trash-guides)
[INF] Initializing provider: official (type: config-templates)
```

Finding:

- `TEMPLATE_NAME` was only a placeholder, not an actual template ID.
- The command initialized the official providers but did not produce the expected usable template-based configuration.
- A valid Recyclarr v8 template ID is still needed before generating a real service config.

Attempted to list templates with a raw output flag:

```bash
docker exec recyclarr recyclarr config list templates --raw
```

Observed result:

```text
Error: Unknown option 'raw'.
```

Finding:

- Recyclarr v8 does not support `--raw` for `config list templates`.
- Template discovery needs to use the supported default output from:

```bash
docker exec recyclarr recyclarr config list templates
```

Help text was also checked during template discovery:

```bash
docker exec recyclarr recyclarr config list templates --help
```

Finding:

- The help output did not provide a usable raw/listing shortcut for template IDs.
- The next session should capture the normal template list output exactly as displayed, then use a real listed template identifier.

No `sync`, `sync --preview`, or real profile changes were run during this session.

## Issue Encountered: Config Folder Permissions

The first config creation attempt failed with a permission error:

```text
Access to the path '/config/state' is denied.
```

Cause:

The container was running as UID/GID `1000:1000`, but the mounted config directory was not writable by that user.

Fix:

```bash
chown -R 1000:1000 /volume1/docker/recyclarr
chmod -R u+rwX,g+rwX /volume1/docker/recyclarr
```

After this, Recyclarr was able to create its config structure.

## Recyclarr v8 Notes

The Recyclarr v8 CLI differs from older guides.

Important observations:

- The Docker image is pinned to `ghcr.io/recyclarr/recyclarr:8`.
- The old `create-config` command is not valid.
- The v8 command is `recyclarr config create`.
- `recyclarr config list` requires a subcommand such as `local` or `templates`.
- `recyclarr config list templates` confirmed templates are available.
- `recyclarr config create -t TEMPLATE_NAME` should not be used literally because `TEMPLATE_NAME` is only a placeholder.
- `recyclarr config list templates --raw` is invalid in Recyclarr v8.
- The safe next step is always to verify local configs and use `sync --preview` before any real sync.

## Validation Completed

Container running:

```text
recyclarr   ghcr.io/recyclarr/recyclarr:8   Up
```

Startup log showed:

```text
Starting cron schedule using: @daily
```

Template providers initialized:

```text
Initializing provider: official (type: trash-guides)
Initializing provider: official (type: config-templates)
```

Latest active config check showed only:

```text
uhd-bluray-web.yml
```

## Backup and Rollback Plan

Current rollback for the latest config cleanup:

1. Move the disabled config back into the active config directory:

```bash
sudo mv /volume1/docker/recyclarr/config/configs-disabled/remux-2160p-combined.yml /volume1/docker/recyclarr/config/configs/remux-2160p-combined.yml
```

2. Confirm both configs are present if the combined Remux config is needed again:

```bash
sudo ls -la /volume1/docker/recyclarr/config/configs
```

3. Run preview before applying anything:

```bash
docker exec recyclarr recyclarr sync --preview
```

General rollback for Recyclarr-only work:

1. Stop and remove the Recyclarr stack in Portainer.
2. Optionally remove the config directory:

```bash
rm -rf /volume1/docker/recyclarr
```

3. Confirm Sonarr and Radarr are unaffected or restore their profile settings from backup/export if a real sync had already been applied.

Future rollback before applying templates or new configs:

- Export or document current Sonarr and Radarr quality profiles.
- Save a copy of the Recyclarr config before each major change.
- Use `sync --preview` before any real sync.
- Do not run a real `sync` until the preview output has been reviewed.

## Review Checkpoint

Before continuing Recyclarr implementation, review this documentation and confirm:

- The current status still matches the NAS.
- The stack path and mounted config path are correct.
- `uhd-bluray-web.yml` is the only active config currently intended to run.
- `remux-2160p-combined.yml` should remain disabled for now.
- The next session will use `sync --preview` before any real sync.

## Next Session Checklist

- Confirm local configs:

```bash
docker exec recyclarr recyclarr config list local
```

- Confirm active config files:

```bash
ls -la /volume1/docker/recyclarr/config/configs
ls -la /volume1/docker/recyclarr/config/configs-disabled
```

- Review `uhd-bluray-web.yml` before syncing.
- Run preview only:

```bash
docker exec recyclarr recyclarr sync --preview
```

- Review proposed changes before applying.
- If the preview looks correct, decide whether to apply only the active `uhd-bluray-web.yml` config.
