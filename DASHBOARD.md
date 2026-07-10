# Homelab Project Dashboard

> Last updated: 2026-07-10

This file is the quick-glance source of truth for active homelab work. Update it whenever a project starts, changes priority, becomes blocked, or is completed.

## Current Priority

### 1. Deploy Unpackerr

**Status:** Next up

Goal: Automatically extract archived downloads so Radarr and Sonarr can import them without manual intervention.

Planned work:

- Review qBittorrent, Radarr, and Sonarr paths and categories.
- Deploy Unpackerr through Portainer as a Docker Compose stack.
- Connect Unpackerr to Radarr and Sonarr.
- Confirm archive extraction and cleanup behavior.
- Add service documentation and validation commands.

## Near-Term Queue

### 2. Watchtower label-based updates

**Status:** Planned

- Convert from broad automatic updates to explicit opt-in labels.
- Keep stateful and critical services excluded.
- Define a weekly maintenance window.
- Add cleanup and notification behavior.
- Update the Watchtower documentation.

### 3. Ansible control node on the UGREEN NAS

**Status:** Planned

- Create a Git-backed Ansible repository.
- Configure inventory and `ansible.cfg`.
- Establish SSH key authentication.
- Build initial Linux and Docker playbooks.
- Document the control-node workflow.

### 4. Raspberry Pi Ansible managed host

**Status:** Planned

- Prepare and harden the Raspberry Pi.
- Configure SSH access.
- Add it to the Ansible inventory.
- Validate initial playbooks.

## Later Projects

- [ ] Home Assistant with Apple Home integration
- [ ] SearXNG integration with Open WebUI
- [ ] RAG document library for local AI
- [ ] MAAS deployment lab
- [ ] Reusable PowerShell and shell diagnostic helpers
- [ ] Plex remote-access design without unnecessary public exposure

## Completed Projects

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

- [ ] Confirm all service documentation matches the live Portainer stacks.
- [ ] Review backup coverage for stateful container data.
- [ ] Add maintenance windows to Uptime Kuma for planned updates.
- [ ] Periodically verify qBittorrent and Gluetun recovery behavior.
- [ ] Keep this dashboard updated at the end of each project session.

## Project Workflow

For each project:

1. Record the project here before work begins.
2. Document the current state and rollback plan.
3. Make and validate one logical change at a time.
4. Update the relevant service or networking document.
5. Mark the project complete here.
6. Commit and push the documentation changes.
