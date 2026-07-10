# Homelab Project Dashboard

> Last updated: 2026-07-10

This file is the quick-glance source of truth for active homelab work. Update it whenever a project starts, changes priority, becomes blocked, or is completed.

## Current Priority

### 1. Home Assistant with Apple Home integration

**Status:** Next up

Goal: Deploy Home Assistant in a maintainable way and integrate compatible devices with Apple Home.

Planned work:

- Review deployment choices and select the best fit for the UGREEN NAS.
- Deploy through Portainer when practical.
- Configure persistent storage and backups.
- Add Apple Home integration.
- Validate device discovery and remote behavior.
- Document deployment, recovery, and update procedures.

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

- [x] Reusable shell diagnostics toolkit
  - Added concise Docker health, Compose inventory, and network reports
  - Added focused Watchtower and qBittorrent/Gluetun reports
  - Limited recent logs to keep troubleshooting output manageable
  - Added usage and design guidance under `diagnostics/README.md`
  - PowerShell wrappers remain an optional future enhancement
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

- [ ] Confirm the first GitHub Actions Compose-validation run succeeds.
- [ ] Add PowerShell wrappers for remote diagnostics if the shell scripts become part of regular troubleshooting.
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
