# Recyclarr

## Purpose

Recyclarr is used to manage and synchronize Sonarr and Radarr quality profiles, custom formats, and TRaSH Guides recommendations. The goal is to make media quality configuration easier to maintain over time instead of manually rebuilding profiles in each application.

This project is being implemented in short sessions to avoid risky, late-night profile changes.

Last updated: **2026-07-04**

## Current Status

Status: **In Progress**

Important safety note: Recyclarr has been deployed and tested, but no real `sync` has been run yet. Sonarr and Radarr profiles have not been changed by Recyclarr.

Session 1 completed:

- Deployed Recyclarr as a dedicated Portainer Stack.
- Confirmed the container is running.
- Attached Recyclarr to the existing `media-net` Docker network.
- Created and initialized the Recyclarr configuration directory.
- Fixed container volume permissions.
- Confirmed Recyclarr can initialize the official resource providers for TRaSH Guides and config templates.
- No Sonarr or Radarr changes were applied.

Session 2 completed:

- Reviewed Recyclarr v8 CLI behavior while attempting to move from deployment into template-based configuration.
- Confirmed the Recyclarr v8 CLI does not support the older/example `--raw` flag for template listing.
- Confirmed `recyclarr config create -t TEMPLATE_NAME` initializes the official providers but does not create a usable config when `TEMPLATE_NAME` is only a placeholder.
- Confirmed the local template workflow needs the actual template identifier before a real config can be generated.
- Stopped before applying any templates or syncing changes into Sonarr or Radarr.
- No Sonarr or Radarr changes were applied.

Session 3 planned:

- Run the supported template list command and capture the actual available template IDs.
- Identify the correct Recyclarr v8 template IDs for the intended Sonarr and Radarr setup.
- Generate a real Sonarr and/or Radarr template config using an actual template ID.
- Configure Sonarr and Radarr connectivity.
- Add API keys safely.
- Run `sync --preview` only.
- Review proposed changes before applying anything.

Session 4 planned:

- Apply approved configuration.
- Validate profiles in Sonarr and Radarr.
- Fine tune quality, anime, 1080p, and 4K behavior.
- Complete final documentation.

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
/config/includes
/config/logs
/config/resources
/config/state
/config/settings.yml
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

Important observations from Session 1:

- The Docker image is pinned to `ghcr.io/recyclarr/recyclarr:8`.
- The old `create-config` command is not valid.
- The v8 command is `recyclarr config create`.
- `recyclarr config list` requires a subcommand such as `local` or `templates`.
- `recyclarr config list templates` confirmed templates are available.
- More research is needed before applying templates because older examples may not match v8 behavior.

Important observations from Session 2:

- `recyclarr config create -t TEMPLATE_NAME` should not be used literally because `TEMPLATE_NAME` is only a placeholder.
- `recyclarr config list templates --raw` is invalid in Recyclarr v8.
- The next safe step is to list the available templates using the supported command, choose the correct template ID, and then create a config from that exact ID.
- No Sonarr or Radarr profile changes have been made yet.

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

## Backup and Rollback Plan

No Sonarr or Radarr profile changes were applied in Session 1 or Session 2.

Rollback for current Recyclarr-only work:

1. Stop and remove the Recyclarr stack in Portainer.
2. Optionally remove the config directory:

```bash
rm -rf /volume1/docker/recyclarr
```

3. Confirm Sonarr and Radarr are unaffected.

Future rollback before applying templates:

- Export or document current Sonarr and Radarr quality profiles.
- Save a copy of the Recyclarr config before each major change.
- Use `sync --preview` before any real sync.
- Do not run a real `sync` until the preview output has been reviewed.

## Review Checkpoint

Before continuing Recyclarr implementation, review this documentation and confirm:

- The current status still matches the NAS.
- The stack path and mounted config path are correct.
- Recyclarr is still only staged and has not modified Sonarr or Radarr.
- The next session will use `sync --preview` before any real sync.

## Next Session Checklist

- Run the supported template list command:

```bash
docker exec recyclarr recyclarr config list templates
```

- Capture the full template list output in the session notes.
- Identify the correct template ID for the intended Sonarr and Radarr setup.
- Generate a config using the actual template ID, not the placeholder:

```bash
docker exec recyclarr recyclarr config create -t <actual-template-id>
```

- Configure Sonarr API connection.
- Configure Radarr API connection.
- Run preview only:

```bash
docker exec recyclarr recyclarr sync --preview
```

- Review proposed changes before applying.
