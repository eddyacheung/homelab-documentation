# Homelab Documentation

Documentation and version-controlled infrastructure definitions for my homelab, Linux administration, Docker environment, networking, and self-hosted services.

## Quick Navigation

- [`DASHBOARD.md`](DASHBOARD.md) - current priority, project queue, completed work, and follow-ups
- [`docker/README.md`](docker/README.md) - complete Docker stack index and deployment workflow
- [`diagnostics/README.md`](diagnostics/README.md) - reusable, read-only troubleshooting reports
- [`architecture/homelab-dependency-map.md`](architecture/homelab-dependency-map.md) - visual service, networking, and operations map
- [`ai/open-webui-homelab-context.md`](ai/open-webui-homelab-context.md) - safe plan for using this repository as Open WebUI knowledge
- [`services/home-assistant-tesla-dashboard.md`](services/home-assistant-tesla-dashboard.md) - TeslaMate telemetry dashboard, ApexCharts, entities, validation, and rollback
- [`services/home-assistant-eufy-cameras.md`](services/home-assistant-eufy-cameras.md) - Eufy camera integration, HomeKit evaluation, and architecture decision
- [`services/home-assistant-presence-security.md`](services/home-assistant-presence-security.md) - Companion App presence, Home/Away automations, and reusable Eufy scripts
- [`services/home-assistant-apple-tv.md`](services/home-assistant-apple-tv.md) - Apple TV discovery, pairing diagnostics, security settings, and validation

## Hardware

- UGREEN DXP4800 Plus with 64 GB RAM
- Windows desktop with NVIDIA RTX 4070
- Raspberry Pi 4

## Repository Structure

```text
DASHBOARD.md      Current project priorities and status
architecture/     Dependency maps and system-level design
ai/               Local-AI context, RAG, and integration guidance
diagnostics/      Read-only Docker and service troubleshooting reports
docker/           Version-controlled Compose stacks and stack READMEs
services/         Individual service documentation
networking/       DNS, Docker networking, UniFi, Tailscale
linux/            Linux administration notes and references
windows/          Windows administration and PowerShell references
scripts/          Repository validation and operational helpers
standards/        Change management and operational standards
troubleshooting/  Recovery guides and troubleshooting notes
changes/          Dated infrastructure change notes
.github/          Automated repository quality checks
```

## Core Services

- Portainer
- Watchtower
- Open WebUI
- Plex
- Sonarr
- Radarr
- Prowlarr
- qBittorrent
- Gluetun
- Seerr
- Pi-hole
- Unbound
- Nginx Proxy Manager
- Cloudflare Tunnel
- Recyclarr
- Unpackerr
- Uptime Kuma
- Homebridge
- Home Assistant
- go2rtc
- eufy-security-ws
- TeslaMate

## Current Infrastructure

- Docker Compose definitions stored in Git
- Portainer stack deployment and management
- Pi-hole with Unbound recursive DNS
- Nginx Proxy Manager reverse proxy
- Cloudflare Tunnel and Zero Trust access
- UniFi networking
- Tailscale remote access
- Home Assistant camera entities and WebRTC dashboards
- Homebridge camera export to Apple Home
- Companion App occupancy tracking with validated Home/Away Eufy guard-mode automation
- Native Home Assistant control of Bedroom and Game Room Apple TVs
- TeslaMate self-hosted vehicle analytics
- Home Assistant Voyager dashboard using TeslaMate MQTT telemetry and ApexCharts
- Automated Compose repository validation through GitHub Actions
- Reusable diagnostics for Docker health, Compose projects, networks, Watchtower, and qBittorrent/Gluetun

## Infrastructure-as-Code Workflow

The intended change flow is:

```text
Git repository -> review and validation -> Portainer deployment -> live verification -> documentation update
```

Each Docker stack lives under `docker/<stack-name>/` with:

- `docker-compose.yml`
- `README.md`
- `.env.example` when variables or secrets are required

Real `.env` files and credentials are excluded from Git.

## Recent Infrastructure Work

### Home Presence and Security Automation Completion - 2026-07-21

- Completed natural arrival and departure soak testing.
- Confirmed Home and Away scripts, automations, and Companion App notifications operate reliably.
- Moved the project from active work to completed status.
- Retained manual override or guest mode as an optional future enhancement.

### Home Assistant Tesla Dashboard - 2026-07-17

- Built the Voyager three-column Tesla dashboard from TeslaMate MQTT telemetry.
- Added vehicle, battery, charging, climate, security, opening, location, odometer, and tire-pressure cards.
- Installed ApexCharts Card and replaced the stock battery-history graph with a blue 24-hour area chart.
- Added conditional charging metrics for plugged-in and unplugged states.
- Corrected range units, hero-image clipping, and YAML rollback procedures.
- Selected the last aligned dashboard as the Version 1 baseline after rejecting a sparse deduplicated experiment.
- Documented entities, validation, backup, recovery, and future Version 2 ideas.

### Home Presence, Eufy Automation, and Apple TV - 2026-07-14

- Connected the Home Assistant Companion App and validated GPS, Wi-Fi, battery, and connection sensors.
- Corrected the Home zone and confirmed the iPhone device tracker and person entity report occupancy accurately.
- Created arrival and five-minute delayed departure automations.
- Refactored Eufy mode changes into reusable Home and Away scripts for the Bedroom and Living Room cameras.
- Verified Home Assistant mode changes are reflected in the Eufy app.
- Paired Bedroom and Game Room Apple TVs after isolating a `pyatv` authentication problem.
- Confirmed play/pause control and media-state updates from Home Assistant.
- Tightened Apple TV AirPlay access to devices on the same network and confirmed control remained functional.

### Home Assistant and Eufy Camera Evaluation - 2026-07-13

- Integrated Eufy cameras with Home Assistant through `eufy-security-ws` and `go2rtc`.
- Built and validated a WebRTC camera dashboard.
- Tested standalone HomeKit camera accessories exported by Home Assistant.
- Documented the disable/re-enable method for regenerating missing HomeKit QR-code notifications.
- Compared Apple Home performance and retained Homebridge for Eufy camera export because it delivered approximately two-second stream startup.
- Added a Home Presence and Security Automation project for occupancy-driven camera behavior.

### Diagnostics Toolkit - 2026-07-10

- Added reusable, read-only shell reports under `diagnostics/`.
- Standardized Docker health, Compose inventory, and network summaries.
- Added focused Watchtower and qBittorrent/Gluetun reports.
- Limited log output so reports remain practical to paste into troubleshooting sessions.

### Compose Source-of-Truth Project - 2026-07-10

- Exported and sanitized 17 Docker Compose stacks.
- Added `.env.example` files for secret-bearing stacks.
- Added a self-contained README to every stack directory.
- Added a Docker stack index and dependency diagrams.
- Added automated validation for Compose syntax, README coverage, and environment-variable examples.
- Added guidance for ingesting the repository into Open WebUI as a safe knowledge source.

### Recyclarr Completion - 2026-07-10

- Verified Radarr and Sonarr connectivity.
- Applied the official `UHD Bluray + WEB` Radarr profile.
- Applied the official `WEB-2160p` Sonarr profile.
- Confirmed custom formats, quality definitions, and profiles are current.
- Verified the daily scheduled synchronization succeeds.
- Moved the unused placeholder configuration to `configs-disabled`.

### Portainer Stack Cleanup - 2026-07-08

- Migrated qBittorrent and Gluetun into a Portainer-managed stack.
- Reattached Gluetun to `media-net` and restored dependent service access.
- Restored Watchtower as a Portainer-managed stack.
- Fixed Docker API compatibility and disabled incompatible rolling restarts.
- Standardized the Plex stack name while preserving its data and libraries.

## Active Projects

The actively maintained list lives in [`DASHBOARD.md`](DASHBOARD.md).

Current next project: **Homelab PowerShell Toolkit**.

## Current Learning Goals

- Linux administration
- Docker and Docker Compose
- Git and GitHub
- Python
- Ansible
- Canonical MAAS
- Cloudflare Tunnel
- SearXNG
- Retrieval-Augmented Generation

## Documentation Philosophy

Every significant infrastructure change should include:

1. Backup and rollback planning
2. Implementation
3. Validation
4. Documentation
5. Git commit

The goal is to keep this repository synchronized with the actual homelab so it functions as documentation, a recovery kit, and an operational knowledge base.
