# Watchtower

## Purpose

Watchtower monitors Docker images and recreates containers when updates are available.

In this homelab, Watchtower is deployed as a Portainer-managed stack and uses a conservative label-based opt-in policy. Only containers explicitly approved with the Watchtower enable label are eligible for automatic updates.

---

## Deployment

| Setting | Value |
| --- | --- |
| Host | UGREEN DXP4800 Plus |
| Stack name | `watchtower` |
| Container name | `watchtower` |
| Image | `containrrr/watchtower:latest` |
| Deployment method | Portainer stack |
| Compose source | Portainer Editor |
| Supporting host path | `/volume1/docker/watchtower/docker-compose.yml` |

The Watchtower stack was redeployed through Portainer on 2026-07-08 so the Portainer **Editor** tab is available.

---

## Current Configuration

Important settings:

```yaml
TZ: America/Chicago
DOCKER_API_VERSION: "1.40"
WATCHTOWER_CLEANUP: "true"
WATCHTOWER_REMOVE_VOLUMES: "false"
WATCHTOWER_LABEL_ENABLE: "true"
WATCHTOWER_INCLUDE_STOPPED: "false"
WATCHTOWER_INCLUDE_RESTARTING: "true"
WATCHTOWER_ROLLING_RESTART: "false"
WATCHTOWER_TIMEOUT: "30s"
WATCHTOWER_LOG_FORMAT: pretty
WATCHTOWER_SCHEDULE: "0 0 12 * * *"
```

Schedule meaning:

```text
Every day at 12:00 PM Central time
```

Watchtower currently runs without notifications.

---

## Docker API Compatibility

Watchtower previously entered a restart loop with this error:

```text
client version 1.25 is too old. Minimum supported API version is 1.40
```

The fix was to explicitly set:

```yaml
DOCKER_API_VERSION: "1.40"
```

Keep this value in place unless Docker Engine or Watchtower behavior changes and the setting is retested.

---

## Rolling Restart Disabled

Rolling restart is disabled:

```yaml
WATCHTOWER_ROLLING_RESTART: "false"
```

Reason: qBittorrent uses Gluetun as its network namespace with:

```yaml
network_mode: service:gluetun
```

Watchtower reported that qBittorrent depends on another container and that this is not compatible with rolling restarts. Disabling rolling restarts prevents Watchtower from failing against dependency-linked containers.

---

## Label-Based Opt-In Update Strategy

Watchtower is configured with:

```yaml
WATCHTOWER_LABEL_ENABLE: "true"
```

This means Watchtower ignores containers unless they explicitly contain the enable label.

Approved containers use this service-level Compose label:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

Example:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    labels:
      - com.centurylinklabs.watchtower.enable=true
```

The label belongs inside the individual service definition at the same indentation level as `image`, `container_name`, `restart`, `volumes`, and `networks`.

Containers without the label remain manual-update only. This is intentional for critical, stateful, or tightly coupled services.

Particular care should be taken with:

- qBittorrent and Gluetun
- Plex
- Pi-hole and Unbound
- Portainer
- databases
- dependency-linked or stateful containers

The live Portainer stack definitions remain the source of truth for which containers are currently opted in.

---

## Verification Commands

Check container status:

```bash
docker ps --filter name=watchtower
```

Expected result:

```text
watchtower   Up ... (healthy)
```

View recent logs:

```bash
docker logs --tail=50 watchtower
```

Expected healthy startup includes:

```text
Watchtower 1.7.1
Only checking containers using enable label
Scheduling first run
```

Inspect the complete container definition from Windows PowerShell:

```powershell
ssh ugreen "sudo docker inspect watchtower" > .\watchtower-inspect.json
$wt = Get-Content .\watchtower-inspect.json -Raw | ConvertFrom-Json
$wt[0].Config.Env | Sort-Object
```

Expected environment value:

```text
WATCHTOWER_LABEL_ENABLE=true
```

Inspect labels on a candidate container:

```powershell
ssh ugreen "sudo docker inspect cloudflared" > .\cloudflared-inspect.json
$cf = Get-Content .\cloudflared-inspect.json -Raw | ConvertFrom-Json
$cf[0].Config.Labels
```

Expected label:

```text
com.centurylinklabs.watchtower.enable : true
```

---

## Recovery

If Watchtower causes problems, stop it first:

```bash
docker stop watchtower
```

To recreate from the host-side Compose file:

```bash
cd /volume1/docker/watchtower
docker compose up -d
```

Preferred management is through the Portainer stack named `watchtower`.

To temporarily stop all automatic updates without removing labels, disable or stop the Watchtower container.

To return to broad scanning, `WATCHTOWER_LABEL_ENABLE` could be changed back to `false`, but this is not the recommended operating state.

---

## Cleanup History

### 2026-06-28

An older Watchtower compose folder was archived:

```text
/volume1/docker/portainer/compose-archive/watchtower-old-3-2026-06-28-1542
```

### 2026-07-08

Watchtower was recreated as a proper Portainer-managed stack after a restart loop was fixed.

Key fixes:

- Added `DOCKER_API_VERSION=1.40`
- Disabled rolling restarts
- Restored Portainer Editor access
- Verified the container became healthy

### 2026-07-10

The label-based opt-in project was completed.

Validation performed:

- Confirmed the container was healthy.
- Confirmed the previous live configuration used `WATCHTOWER_LABEL_ENABLE=false` and scanned all containers except explicit exclusions.
- Added the missing Watchtower enable label to the Cloudflare Tunnel service.
- Confirmed the remaining intended automatic-update containers already had labels.
- Changed `WATCHTOWER_LABEL_ENABLE` to `true` in the Watchtower stack.
- Redeployed the stack.
- Confirmed the live environment reports `WATCHTOWER_LABEL_ENABLE=true`.
- Confirmed startup logs report `Only checking containers using enable label`.

---

## Lessons Learned

- Watchtower should be treated carefully because it can recreate critical infrastructure containers.
- `DOCKER_API_VERSION=1.40` is required in this environment.
- `WATCHTOWER_ROLLING_RESTART=false` is required with the current qBittorrent/Gluetun dependency pattern.
- Label-based opt-in is safer than broad automatic scanning because eligibility is explicit in each service's Compose definition.
- A container label does not activate opt-in mode by itself; `WATCHTOWER_LABEL_ENABLE=true` must also be set on Watchtower.
- The Watchtower log line `Only checking containers using enable label` is the clearest operational confirmation that opt-in mode is active.
