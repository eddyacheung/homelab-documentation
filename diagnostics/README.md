# Diagnostics Toolkit

Reusable, read-only shell scripts for collecting concise homelab troubleshooting reports.

## Purpose

These scripts reduce long command chains and oversized log dumps. Each script focuses on one troubleshooting question and prints a consistent, copy-friendly report.

## Usage

Run the scripts on the UGREEN NAS, where Docker is available:

```bash
bash diagnostics/docker-health.sh
bash diagnostics/compose-summary.sh
bash diagnostics/network-summary.sh
bash diagnostics/watchtower-report.sh
bash diagnostics/qbittorrent-report.sh
```

From Windows, run them remotely through SSH after pulling the repository onto the NAS, or copy an individual script to the NAS:

```powershell
ssh ugreen "bash /path/to/homelab-documentation/diagnostics/watchtower-report.sh"
```

To save a report locally in PowerShell:

```powershell
ssh ugreen "bash /path/to/homelab-documentation/diagnostics/watchtower-report.sh" > .\watchtower-report.txt
```

## Design Rules

- Read-only by default
- No automatic restarts or configuration changes
- Recent logs are limited to avoid giant outputs
- Secrets are not intentionally printed
- Reports use clear section headings
- Missing containers or commands produce warnings instead of abrupt failures

## Included Reports

| Script | Purpose |
| --- | --- |
| `docker-health.sh` | Running state, health, restart counts, and recent unhealthy containers |
| `compose-summary.sh` | Compose projects, source files, images, and container membership |
| `network-summary.sh` | Docker networks and container membership |
| `watchtower-report.sh` | Watchtower mode, schedule, labels, health, and recent logs |
| `qbittorrent-report.sh` | qBittorrent and Gluetun state, dependency details, VPN reachability, and recent logs |

## Future Reports

Potential additions:

- Pi-hole and Unbound DNS report
- Plex transcoding and reachability report
- Radarr/Sonarr import-path report
- Cloudflare Tunnel report
- Portainer stack inventory export
