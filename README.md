# Homelab Documentation

Documentation for my homelab, Linux administration, Docker infrastructure, networking, and self-hosted services.

## Hardware

- UGREEN DXP4800 Plus (64 GB RAM)
- Windows desktop with NVIDIA RTX 4070
- Raspberry Pi 4

## Repository Structure

```text
services/         Individual service documentation
networking/       DNS, Docker networking, UniFi, Tailscale
linux/            Linux administration notes and references
windows/          Windows administration and PowerShell references
docker/           Docker concepts and platform documentation
standards/        Change management and operational standards
troubleshooting/  Recovery guides and troubleshooting notes
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
- Seerr
- Pi-hole
- Unbound
- Nginx Proxy Manager
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
