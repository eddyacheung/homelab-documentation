# Homelab Documentation

Documentation and version-controlled infrastructure definitions for my homelab, Linux administration, Docker environment, networking, and self-hosted services.

## Quick Navigation

- [`DASHBOARD.md`](DASHBOARD.md) - current priority, project queue, completed work, and follow-ups
- [`docker/README.md`](docker/README.md) - complete Docker stack index and deployment workflow
- [`diagnostics/README.md`](diagnostics/README.md) - reusable, read-only troubleshooting reports
- [`architecture/homelab-dependency-map.md`](architecture/homelab-dependency-map.md) - visual service, networking, and operations map
- [`ai/open-webui-homelab-context.md`](ai/open-webui-homelab-context.md) - safe plan for using this repository as Open WebUI knowledge
- [`services/home-assistant-eufy-cameras.md`](services/home-assistant-eufy-cameras.md) - Eufy camera integration, HomeKit evaluation, and architecture decision

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

Current next project: **Home Presence and Security Automation**.

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
