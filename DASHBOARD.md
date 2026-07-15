# Homelab Project Dashboard

> Last updated: 2026-07-14

This file is the quick-glance source of truth for active homelab work. Update it whenever a project starts, changes priority, becomes blocked, or is completed.

## Current Priority

### 1. Home Presence and Security Automation

**Status:** Implemented, soak testing

Goal: Use Home Assistant as the source of truth for occupancy and automatically apply the desired Eufy security behavior without sacrificing fast Apple Home live viewing.

Completed:

- Connected and configured the Home Assistant Companion App on the iPhone.
- Enabled Always and Precise location access, Local Network access, background updates, and notifications.
- Validated GPS, Wi-Fi, connection, battery, and charging sensors.
- Corrected the Home zone and set a 100-meter radius.
- Confirmed the iPhone device tracker and person entity transition correctly between Home and Away.
- Confirmed the Eufy Security integration exposes Home and Away guard-mode controls.
- Created `Eufy - Set Home Mode` and `Eufy - Set Away Mode` scripts.
- Created `Presence - Arrived Home` and `Presence - Left Home` automations.
- Added a five-minute confirmed-away delay before running the Away script.
- Verified script-driven mode changes for the Bedroom and Living Room cameras.
- Verified Home Assistant changes are reflected in the Eufy app.
- Retained Homebridge for fast Apple Home live camera viewing.

Current behavior:

- Home: Bedroom and Living Room cameras use Eufy Home guard mode.
- Away for five minutes: Bedroom and Living Room cameras use Eufy Away guard mode.
- Temporary Companion App notifications remain enabled during soak testing.

Remaining work:

- Validate several natural arrival and departure cycles.
- Confirm the exact recording, detection, alarm, and notification settings assigned to Eufy Home and Away modes.
- Remove temporary notifications after reliable operation is confirmed.
- Add a manual override or guest-mode helper.
- Investigate true Privacy Mode only if it can coexist with the desired Apple Home live-view behavior.
- Consider UniFi-assisted presence only if Companion App tracking proves unreliable.

Documentation:

- `services/home-assistant-presence-security.md`
- `services/home-assistant-eufy-cameras.md`

## Near-Term Queue

### 2. TeslaMate self-hosted vehicle analytics

**Status:** Planned

Goal: Deploy TeslaMate for private, self-hosted Tesla charging, efficiency, and driving-history analytics while minimizing vehicle-control and location-data exposure.

Security requirements:

- Keep TeslaMate and Grafana accessible only from the LAN or through Tailscale.
- Do not publish TeslaMate through a public Cloudflare hostname.
- Use a dedicated Docker network rather than attaching the stack to `media-net`.
- Keep Tesla tokens, database credentials, and the TeslaMate encryption key outside Git.
- Do not install a Tesla virtual key unless a later requirement clearly justifies vehicle-command access.
- Encrypt PostgreSQL backups and limit retention because the database contains detailed location history.
- Avoid unattended PostgreSQL major-version upgrades and document the backup, upgrade, validation, and rollback process.

Planned work:

- Confirm the currently supported TeslaMate authentication method for a personal Tesla account.
- Design a Portainer stack for TeslaMate, PostgreSQL, Grafana, and any required MQTT components.
- Restrict published ports and verify that PostgreSQL and MQTT are not exposed unnecessarily.
- Deploy with unique generated secrets and sanitized `.env.example` documentation.
- Validate charging-session history, energy-added data, vehicle sleep behavior, and dashboard access.
- Add Home Assistant integration only for useful read-only sensors after the base deployment is stable.
- Document token revocation, backup recovery, upgrades, and complete removal.

### 3. Homelab PowerShell Toolkit

**Status:** Planned

Goal: Provide one-command Windows-native diagnostics and repository helpers without cloning the Git repository onto the NAS.

Design principle:

- Windows remains the primary workstation and local Git checkout.
- GitHub remains the source of truth.
- The UGREEN NAS remains the Docker execution environment.
- Avoid extra synchronization steps unless they provide clear operational value.

Planned work:

- Add PowerShell wrappers around SSH-based Docker diagnostics.
- Create simple commands for Watchtower, qBittorrent/Gluetun, Docker health, networks, and Compose inventory.
- Normalize line endings and remote `sudo` handling automatically.
- Save reports to local files when output is too large for the terminal or chat.
- Add `homelab-health`, `homelab-report`, and `homelab-update` helpers.
- Document installation, aliases, usage, and troubleshooting.

### 4. RAG document library for local AI

**Status:** Planned, groundwork documented

- Use `ai/open-webui-homelab-context.md` as the ingestion and evaluation plan.
- Make the homelab documentation searchable from Open WebUI.
- Define a reliable ingestion and refresh workflow.
- Test answers against known service and troubleshooting notes.
- Prevent secrets and sensitive configuration from entering the knowledge base.

### 5. SearXNG integration with Open WebUI

**Status:** Planned

- Deploy a private metasearch service.
- Connect it to Open WebUI for current web research.
- Tune search engines, networking, and privacy settings.
- Document validation and recovery procedures.

### 6. Plex remote-access design

**Status:** Planned

- Review options that avoid unnecessary public exposure.
- Preserve convenient access for shared Plex users.
- Document security and availability tradeoffs.

### 7. Ansible automation lab

**Status:** Planned, second to last

- Configure the UGREEN NAS as an Ansible control node.
- Create a Git-backed Ansible repository.
- Configure inventory and `ansible.cfg`.
- Establish SSH key authentication.
- Prepare the Raspberry Pi as an Ansible managed host.
- Build and validate initial Linux and Docker playbooks.
- Document the complete control-node and managed-host workflow.

### 8. MAAS deployment lab

**Status:** Planned, last

- Design a small physical provisioning lab.
- Identify suitable controller and managed hardware.
- Document networking, DHCP, imaging, and rollback requirements.

## Completed Projects

- [x] Home Assistant Apple TV integration
  - Paired Bedroom Apple TV 4K (2nd generation)
  - Paired Game Room Apple TV 4K (3rd generation)
  - Diagnosed `pyatv` AirPlay and Companion authentication failures
  - Confirmed discovery, network reachability, and advertised protocols from inside the Home Assistant container
  - Worked around the Python 3.14 `atvremote` event-loop issue for diagnostics
  - Verified play/pause and media-state control from Home Assistant and the Companion App
  - Tightened AirPlay access to anyone on the same network after pairing and revalidated control
  - See `services/home-assistant-apple-tv.md`
- [x] Home Assistant with Apple Home camera integration evaluation
  - Deployed and validated Home Assistant Container with host networking
  - Integrated Eufy cameras through `eufy-security-ws`
  - Deployed and validated `go2rtc` and WebRTC Camera
  - Built a Home Assistant camera dashboard and verified live Backyard streaming
  - Exported and paired standalone HomeKit camera accessories
  - Documented the disable/re-enable method for regenerating HomeKit QR-code notifications
  - Compared Apple Home performance against Homebridge
  - Retained Homebridge for Eufy Apple Home streaming because it loaded in approximately two seconds and outperformed the Home Assistant export
  - Retained Home Assistant camera entities for dashboards, detection entities, and future automation
  - See `services/home-assistant-eufy-cameras.md`
- [x] Reusable shell diagnostics toolkit
  - Added concise Docker health, Compose inventory, and network reports
  - Added focused Watchtower and qBittorrent/Gluetun reports
  - Limited recent logs to keep troubleshooting output manageable
  - Added usage and design guidance under `diagnostics/README.md`
  - PowerShell wrappers are now tracked as the separate Homelab PowerShell Toolkit project
- [x] Version-control all Docker Compose stacks
  - Exported and sanitized 17 live stack definitions
  - Stored each stack under `docker/<stack-name>/docker-compose.yml`
  - Added safe `.env.example` files for secret-bearing stacks
  - Added a tailored README to every stack directory
  - Added `docker/README.md` as the stack index and workflow guide
  - Added Mermaid dependency maps under `architecture/`
  - Added Open WebUI knowledge-ingestion guidance under `ai/`
  - Added GitHub Actions validation for Compose syntax, stack READMEs, and variable examples
- [x] Watchtower label-based opt-in updates
  - `WATCHTOWER_LABEL_ENABLE=true` verified live
  - Startup logs confirm `Only checking containers using enable label`
  - Cloudflared received the missing opt-in label
  - Broad automatic scanning is no longer active
- [x] Unpackerr deployment and integration
  - Connected to the media automation workflow
  - Service deployment and configuration completed
  - First live archived-download extraction remains a natural operational follow-up because no suitable archive was available during deployment
- [x] Recyclarr deployment and configuration
  - Radarr profile: `UHD Bluray + WEB`
  - Sonarr profile: `WEB-2160p`
  - Daily scheduled synchronization verified
  - Unused placeholder configuration moved to `configs-disabled`
- [x] qBittorrent and Gluetun recovery workflow
- [x] Portainer stack cleanup
- [x] Radarr import and Plex connectivity fixes
- [x] Pi-hole and Unbound DNS setup
- [x] Local HTTPS infrastructure
- [x] Cloudflare Tunnel and access controls
- [x] Docker networking cleanup with `media-net`
- [x] Uptime Kuma service documentation
- [x] Git-backed homelab documentation workflow

## Maintenance and Follow-Up

- [ ] Soak test Home/Away presence automation over several natural departures and arrivals.
- [ ] Remove temporary presence notifications after reliability is confirmed.
- [ ] Add a Home Assistant manual override or guest-mode helper for Eufy guard-mode automation.
- [ ] Restore or confirm the Homebridge Eufy plugin after the Home Assistant HomeKit comparison.
- [ ] Remove obsolete Home Assistant camera accessories from Apple Home and disable/delete their accessory-mode HomeKit entries.
- [ ] Confirm Home Assistant WebRTC dashboard streams remain functional after Apple Home cleanup.
- [ ] Confirm the first GitHub Actions Compose-validation run succeeds.
- [ ] Add Pi-hole/Unbound, Plex, and Cloudflare diagnostic reports as needed.
- [ ] Validate Unpackerr against the next naturally occurring archived download.
- [ ] Confirm all service documentation matches the live Portainer stacks.
- [ ] Review backup coverage for stateful container data.
- [ ] Add maintenance windows to Uptime Kuma for planned updates.
- [ ] Periodically verify qBittorrent and Gluetun recovery behavior.
- [ ] Review Watchtower logs after scheduled runs and confirm only opted-in containers are scanned.
- [ ] Build automated Portainer-to-Git drift detection after the manual source-of-truth workflow has matured.
- [ ] Keep this dashboard updated at the end of each project session.

## Project Workflow

For each project:

1. Record the project here before work begins.
2. Document the current state and rollback plan.
3. Make and validate one logical change at a time.
4. Update the relevant service or networking document.
5. Mark the project complete here.
6. Commit and push the documentation changes.
