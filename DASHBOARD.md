# Homelab Project Dashboard

> Last updated: 2026-07-21

This file is the quick-glance source of truth for active homelab work. Update it whenever a project starts, changes priority, becomes blocked, or is completed.

## Current Priority

### 1. Homelab PowerShell Toolkit

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

## Near-Term Queue

### 2. RAG document library for local AI

**Status:** Planned, groundwork documented

- Use `ai/open-webui-homelab-context.md` as the ingestion and evaluation plan.
- Make the homelab documentation searchable from Open WebUI.
- Define a reliable ingestion and refresh workflow.
- Test answers against known service and troubleshooting notes.
- Prevent secrets and sensitive configuration from entering the knowledge base.

### 3. SearXNG integration with Open WebUI

**Status:** Planned

- Deploy a private metasearch service.
- Connect it to Open WebUI for current web research.
- Tune search engines, networking, and privacy settings.
- Document validation and recovery procedures.

### 4. Plex remote-access design

**Status:** Planned

- Review options that avoid unnecessary public exposure.
- Preserve convenient access for shared Plex users.
- Document security and availability tradeoffs.

### 5. Ansible automation lab

**Status:** Planned, second to last

- Configure the UGREEN NAS as an Ansible control node.
- Create a Git-backed Ansible repository.
- Configure inventory and `ansible.cfg`.
- Establish SSH key authentication.
- Prepare the Raspberry Pi as an Ansible managed host.
- Build and validate initial Linux and Docker playbooks.
- Document the complete control-node and managed-host workflow.

### 6. MAAS deployment lab

**Status:** Planned, last

- Design a small physical provisioning lab.
- Identify suitable controller and managed hardware.
- Document networking, DHCP, imaging, and rollback requirements.

## Completed Projects

- [x] Home Presence and Security Automation
  - Connected and configured the Home Assistant Companion App on the iPhone
  - Corrected the Home zone and validated the iPhone tracker and person entity
  - Created reusable Eufy Home and Away scripts
  - Created arrival and five-minute delayed departure automations
  - Verified Home and Away actions against the Eufy app
  - Confirmed Companion App notifications and automation actions operate correctly
  - Completed natural arrival/departure soak testing with no known reliability issues
  - Retained Homebridge for fast Apple Home camera live viewing
  - Manual override or guest mode remains an optional future enhancement
  - See `services/home-assistant-presence-security.md` and `services/home-assistant-eufy-cameras.md`
- [x] Home Assistant Tesla dashboard
  - Built the three-column Voyager dashboard using TeslaMate MQTT telemetry
  - Added vehicle, battery, charging, temperature, odometer, location, opening, lock, Sentry, and tire-pressure cards
  - Replaced the stock history graph with a blue ApexCharts battery-history card
  - Added conditional plugged-in and unplugged charging metrics
  - Corrected range units, dashboard spacing, and hero-image clipping
  - Confirmed the raw vehicle state reports `offline` and avoided relabeling it as sleeping without evidence
  - Selected the last aligned dashboard as the Version 1 rollback baseline
  - Documented rejected experiments, validation, backups, and recovery
  - See `services/home-assistant-tesla-dashboard.md` and `changes/2026-07-17-home-assistant-tesla-dashboard.md`
- [x] TeslaMate self-hosted vehicle analytics
  - Deployed as the Portainer stack `teslamate`
  - Runs TeslaMate and matching Grafana images at version `4.0.1`
  - Uses PostgreSQL, Grafana, and an internal Mosquitto broker
  - Keeps PostgreSQL and MQTT off host-published ports
  - Uses dedicated `teslamate-app` and internal `teslamate-database` networks
  - Resolved Tesla Fleet API `403 Forbidden` vehicle-discovery failures by upgrading from `3.1.0` to `4.0.1`
  - Corrected Grafana network attachment
  - Removed `cap_drop: ALL` from Mosquitto after privilege errors
  - Validated OAuth authentication, vehicle discovery, the first drive, and the first charging session
  - Configured the Home geofence with an effective electricity rate of `$0.13/kWh`
  - Kept the service LAN/Tailscale-only and excluded all four containers from unattended Watchtower updates
  - See `docker/teslamate/README.md` and `services/teslamate.md`
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

- [ ] Validate the Home Assistant Tesla plugged-in conditional cards during a real charging session.
- [ ] Preserve the aligned Tesla dashboard as the Version 1 rollback baseline before a Version 2 redesign.
- [ ] Design secure Home Assistant access to TeslaMate MQTT without exposing an unauthenticated broker broadly.
- [ ] Create and validate an encrypted TeslaMate PostgreSQL backup and recovery procedure.
- [ ] Add a Home Assistant manual override or guest-mode helper for Eufy guard-mode automation if a real need develops.
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
