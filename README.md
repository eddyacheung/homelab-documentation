# Homelab Documentation

Documentation for my homelab, Linux administration, Docker infrastructure, networking, and self-hosted services.

## Project Dashboard

See [`DASHBOARD.md`](DASHBOARD.md) for the current priority, upcoming work, completed projects, and maintenance follow-ups.

## Hardware

- UGREEN DXP4800 Plus (64 GB RAM)
- Windows desktop with NVIDIA RTX 4070
- Raspberry Pi 4

## Repository Structure

```text
DASHBOARD.md      Current project priorities and status
services/         Individual service documentation
networking/       DNS, Docker networking, UniFi, Tailscale
linux/            Linux administration notes and references
windows/          Windows administration and PowerShell references
docker/           Docker concepts and platform documentation
standards/        Change management and operational standards
troubleshooting/  Recovery guides and troubleshooting notes
changes/          Dated infrastructure change notes
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
- Uptime Kuma
- Homarr

## Current Infrastructure

- Docker Compose
- Portainer stack management
- Pi-hole + Unbound recursive DNS
- Nginx Proxy Manager reverse proxy
- Cloudflare Tunnel and Zero Trust access
- UniFi networking
- Tailscale remote access

## Recent Infrastructure Work

### Recyclarr Completion - 2026-07-10

- Verified Radarr and Sonarr connectivity.
- Applied the official `UHD Bluray + WEB` Radarr profile.
- Applied the official `WEB-2160p` Sonarr profile.
- Confirmed custom formats, quality definitions, and profiles are current.
- Verified the daily `@daily` scheduled sync succeeds.
- Moved the unused placeholder `remux-2160p-combined.yml` configuration to `configs-disabled`.

Detailed notes:

```text
services/recyclarr.md
```

### Portainer Stack Cleanup - 2026-07-08

Completed cleanup and standardization for several Docker stacks:

- Migrated qBittorrent and Gluetun from legacy stack `38` to a Portainer-managed `qbittorrent` stack.
- Reattached Gluetun to `media-net` and restored Radarr/Sonarr/Prowlarr access through `gluetun:8888`.
- Converted Watchtower back to a Portainer-managed stack and fixed Docker API compatibility with `DOCKER_API_VERSION=1.40`.
- Disabled Watchtower rolling restarts because they are incompatible with the qBittorrent/Gluetun dependency model.
- Renamed the Plex stack/project from `plexnew` to `plex` while preserving the existing Plex container, config, and libraries.
- Backed up Portainer before testing self-management cleanup, then left it running from the host-side Compose file because full self-management was not worth the added risk.

Detailed notes:

```text
changes/2026-07-08-portainer-stack-cleanup.md
```

## Active Projects

The actively maintained list now lives in [`DASHBOARD.md`](DASHBOARD.md).

Current next project: **Deploy Unpackerr**.

## Networking Documentation

- Docker networking
- Pi-hole
- UniFi Network
- Tailscale
- Nginx Proxy Manager
- Cloudflare Zero Trust

## Current Learning Goals

- Linux Administration
- Docker and Docker Compose
- Git and GitHub
- Python
- Ansible
- Canonical MAAS
- Cloudflare Tunnel
- SearXNG
- Retrieval-Augmented Generation (RAG)

## Documentation Philosophy

Every significant infrastructure change should include:

1. Backup and rollback planning
2. Implementation
3. Validation
4. Documentation
5. Git commit

The goal is to keep this repository synchronized with the actual state of the homelab so it serves as both documentation and an operational knowledge base.
