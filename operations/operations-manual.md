# Homelab Operations Manual

**Owner:** Eddy Cheung  
**Environment:** Personal production homelab  
**Primary host:** UGREEN DXP4800 Plus (`ugreen`)  
**Primary LAN:** `192.168.10.0/24`  
**Local domain:** `*.home`  
**Public domain:** `armouredcore.net`  
**Last reviewed:** 2026-07-19

## 1. Purpose

This manual is the operational source of truth for routine administration, maintenance, security, backup, recovery, and troubleshooting of the homelab.

Use it when:

- performing planned maintenance;
- responding to a service outage;
- validating security controls;
- recovering a container or host;
- introducing a new service;
- updating infrastructure documentation.

The Git repository records intended configuration. The running environment must be validated after every change because documentation and Compose files do not prove that a deployed service is healthy.

## 2. Operating Principles

1. Back up before changing stateful services.
2. Change one dependency layer at a time.
3. Preserve a tested rollback path.
4. Keep secrets out of Git.
5. Validate locally before validating remotely.
6. Record significant changes in the repository.
7. Prefer private access paths over exposed inbound ports.
8. Treat DNS, reverse proxy, authentication, and container networking as separate layers during troubleshooting.

## 3. Environment Summary

### 3.1 Core hardware

| Component | Role |
|---|---|
| UGREEN DXP4800 Plus, 64 GB RAM | Primary Docker host and storage platform |
| Windows desktop, RTX 4070 | Workstation and local AI compute host |
| Raspberry Pi 4 | Lab and future automation or infrastructure testing node |
| UniFi Cloud Gateway Max | Gateway, firewall, routing, and network management |
| UniFi U7 Pro | Primary wireless access point |

### 3.2 Core network identities

| Item | Value |
|---|---|
| NAS hostname | `ugreen` |
| NAS LAN IP | `192.168.10.101` |
| NAS Tailscale address | `100.92.16.79` |
| Desktop LAN IP | `192.168.10.100` |
| Pi-hole address | `192.168.10.250` |
| Local DNS suffix | `.home` |
| Public DNS zone | `armouredcore.net` |

### 3.3 Service groups

**Access and networking**

- Cloudflare Tunnel
- Nginx Proxy Manager
- Pi-hole
- Unbound
- Tailscale
- UniFi

**Home automation**

- Home Assistant
- Homebridge
- go2rtc
- eufy-security-ws
- TeslaMate

**Media platform**

- Plex
- Seerr
- Sonarr
- Radarr
- Prowlarr
- Recyclarr
- Unpackerr
- qBittorrent
- Gluetun

**Operations and tooling**

- Portainer
- Uptime Kuma
- Watchtower
- Open WebUI

## 4. Dependency Model

Use the dependency chain below when diagnosing an outage.

```text
Client
  -> local or public DNS
  -> local network, Tailscale, or Cloudflare edge
  -> Cloudflare Tunnel or Nginx Proxy Manager
  -> Docker network and published port
  -> application container
  -> application data, database, or upstream dependency
```

Examples:

```text
ha.home
  -> Pi-hole local DNS
  -> Nginx Proxy Manager
  -> Home Assistant:8123
```

```text
ha.armouredcore.net
  -> Cloudflare DNS
  -> Cloudflare Tunnel
  -> Home Assistant or Nginx Proxy Manager origin
```

```text
qBittorrent
  -> Gluetun network namespace
  -> VPN provider
  -> tracker and peer connectivity
```

Do not jump directly to rebuilding a container. First identify which layer is failing.

## 5. Access Paths

### 5.1 Local access

Local services use Pi-hole records and Nginx Proxy Manager where appropriate.

Examples:

- `http://ha.home`
- `http://seerr.home`
- `http://portainer.home`
- `http://ugreen.home`

### 5.2 Remote administrative access

Preferred administrative path:

1. Connect through Tailscale.
2. Use the NAS MagicDNS name or Tailscale address.
3. Use SSH only from a trusted device.
4. Avoid opening temporary WAN firewall rules unless no safer path exists.

### 5.3 Public application access

Cloudflare Tunnel is the preferred public ingress path for supported web applications. Public services must not require a direct router port-forward unless a documented protocol limitation makes it necessary.

Plex remote access is the primary known exception and must be reviewed independently from Cloudflare-hosted web applications.

## 6. Cloudflare and Reverse Proxy Security Baseline

The current Home Assistant public path uses Cloudflare Tunnel and remains reachable at both the local and public hostnames.

Baseline controls:

- no direct Home Assistant WAN port-forward;
- Cloudflare Tunnel for public ingress;
- Cloudflare account multi-factor authentication;
- Bot Fight Mode enabled;
- Nginx Proxy Manager `Block Common Exploits` enabled where compatible;
- WebSocket support enabled for Home Assistant;
- Home Assistant trusted-proxy configuration restricted to required proxy networks;
- Home Assistant IP banning enabled;
- failed-login threshold configured;
- public and local access tested after changes.

Cloudflare WAF custom rules were intentionally deferred because the available plan and interface did not expose the desired rule construction. Do not create a broad rule merely to imitate a control that cannot be expressed safely.

### 6.1 mTLS decision

Mutual TLS is not part of the current baseline. It would increase client-management overhead and may interfere with Home Assistant mobile and browser access. Reconsider mTLS only for a narrowly scoped administrative hostname or machine-to-machine endpoint.

### 6.2 Security validation

After changing Cloudflare, Nginx Proxy Manager, or Home Assistant proxy settings, verify:

```text
1. http://ha.home opens from the LAN.
2. https://ha.armouredcore.net opens externally.
3. The Home Assistant mobile app connects.
4. Live dashboards and camera streams still load.
5. Home Assistant logs contain no new proxy or authentication errors.
6. Cloudflare Tunnel reports healthy connections.
```

## 7. Docker Operations

### 7.1 Source of truth

Each managed stack should live under:

```text
docker/<stack-name>/
├── docker-compose.yml
├── README.md
└── .env.example
```

Real `.env` files, API keys, passwords, tokens, certificates, and private keys must not be committed.

### 7.2 Standard inspection commands

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose ls
docker network ls
docker volume ls
docker system df
```

For one service:

```bash
docker inspect <container>
docker logs --tail 200 <container>
docker stats --no-stream <container>
```

For a Compose stack:

```bash
cd /path/to/stack
docker compose config
docker compose ps
docker compose logs --tail 200
```

### 7.3 Safe restart order

1. Confirm the container is unhealthy or a restart is required.
2. Capture recent logs.
3. Identify databases, VPN containers, proxies, and shared networks.
4. Restart only the affected container first.
5. Restart dependencies before dependents when a full stack restart is necessary.
6. Validate application behavior, not only container status.

Example:

```bash
docker restart <container>
docker logs --since 5m <container>
```

### 7.4 qBittorrent and Gluetun

qBittorrent depends on Gluetun for network access. Treat them as one operational unit.

Validation sequence:

```bash
docker ps --filter name=gluetun --filter name=qbittorrent
docker logs --tail 100 gluetun
docker logs --tail 100 qbittorrent
```

Confirm:

- Gluetun reports a healthy VPN connection;
- qBittorrent's web interface is reachable through the published Gluetun port;
- the external IP matches the VPN, not the residential WAN address;
- tracker errors are not caused by DNS or indexer-side protection.

Never temporarily attach qBittorrent directly to the host network as a convenience fix.

## 8. Home Assistant Operations

### 8.1 Deployment

| Item | Value |
|---|---|
| Container | `homeassistant` |
| Image | `ghcr.io/home-assistant/home-assistant:stable` |
| Config path | `/volume1/docker/homeassistant/config` |
| Service port | `8123` |
| Local hostname | `ha.home` |
| Public hostname | `ha.armouredcore.net` |

### 8.2 Configuration validation

Before restarting after YAML changes:

```bash
docker exec homeassistant python -m homeassistant --script check_config --config /config
```

A successful command can return with no detailed output after `Testing configuration at /config`.

Then restart and inspect logs:

```bash
docker restart homeassistant
docker logs --since 5m homeassistant
```

### 8.3 Functional checks

- local web login;
- public web login;
- Companion App connectivity;
- automations loaded;
- camera streams available;
- Apple TV entities responsive;
- Tesla dashboard entities updating;
- Home and Away presence state correct;
- Eufy mode scripts operate as expected.

### 8.4 Home Assistant recovery priority

1. Preserve `/volume1/docker/homeassistant/config`.
2. Copy the current config directory before editing damaged files.
3. Validate YAML.
4. Restore the most recent known-good file or backup.
5. Recreate the container from Compose without deleting the config directory.
6. Revalidate integrations and entity IDs because restored integrations can change generated entities.

## 9. DNS Operations

Pi-hole provides client DNS and local records. Unbound provides recursive upstream resolution.

### 9.1 Failure isolation

Check in this order:

```text
1. Can the client reach 192.168.10.250?
2. Does Pi-hole resolve a public domain?
3. Does Pi-hole resolve the expected .home record?
4. Can Pi-hole reach Unbound?
5. Can Unbound resolve independently?
6. Is the client using the expected DNS server?
```

Useful checks:

```bash
nslookup ha.home 192.168.10.250
nslookup example.com 192.168.10.250
```

From Linux:

```bash
dig @192.168.10.250 ha.home
dig @192.168.10.250 example.com
```

Do not change public Cloudflare DNS to fix a `.home` resolution failure.

## 10. Monitoring and Alerting

Uptime Kuma should monitor critical user-facing endpoints and major infrastructure dependencies.

Minimum monitor set:

- Home Assistant local endpoint;
- Home Assistant public endpoint;
- Plex;
- Seerr;
- Sonarr;
- Radarr;
- Prowlarr;
- qBittorrent web interface;
- Portainer;
- Pi-hole web interface;
- Nginx Proxy Manager;
- TeslaMate or Grafana endpoint where applicable.

An HTTP 200 response is not sufficient for every service. Where practical, monitor a meaningful application path and use keyword validation.

## 11. Backup Policy

### 11.1 Backup priorities

**Tier 1: irreplaceable configuration and state**

- Home Assistant config and backups;
- Docker Compose files and `.env` files stored outside Git;
- database volumes and dumps;
- Nginx Proxy Manager data and certificates;
- Pi-hole and Unbound configuration;
- TeslaMate database;
- Portainer data;
- documentation repository.

**Tier 2: rebuildable application state**

- application databases that can be reconstructed but would require significant work;
- dashboards, custom cards, and automation YAML;
- download-client state;
- media-manager configuration.

**Tier 3: replaceable data**

- container images;
- temporary download data;
- caches;
- generated thumbnails where regeneration is acceptable.

### 11.2 Backup rules

- A bind mount is not a backup.
- RAID or mirroring is not a backup.
- A Git repository does not back up secrets or databases.
- At least one backup copy must be separate from the primary NAS storage pool.
- Backups must be tested by restoring selected files and at least one stateful service periodically.

### 11.3 Pre-change backup

Before changing a stateful service:

```bash
mkdir -p /path/to/backup/<service>-$(date +%F-%H%M)
cp -a /path/to/service/config /path/to/backup/<service>-$(date +%F-%H%M)/
```

Use application-aware database dumps instead of copying a live database directory whenever possible.

## 12. Disaster Recovery

### 12.1 Recovery order

1. Restore host networking and storage.
2. Restore Docker Engine and Compose capability.
3. Restore DNS and remote administrative access.
4. Restore reverse proxy and Cloudflare Tunnel.
5. Restore databases.
6. Restore Home Assistant and other critical applications.
7. Restore media automation and optional services.
8. Validate monitoring.
9. Update documentation with deviations discovered during recovery.

### 12.2 Complete host rebuild

Required inputs:

- this Git repository;
- offline secrets and `.env` backup;
- application-data backup;
- database dumps;
- storage mount definitions;
- DNS records;
- Cloudflare account and tunnel access;
- Tailscale account access.

Rebuild procedure:

1. Install and patch the host OS.
2. Restore storage mounts using stable identifiers.
3. Install Docker Engine and Compose.
4. Recreate external Docker networks required by Compose.
5. Clone the documentation repository.
6. Restore secrets to their documented locations.
7. Restore databases and bind-mounted application data.
8. Deploy foundational stacks first: DNS, proxy, tunnel, monitoring.
9. Deploy stateful applications.
10. Deploy dependent and optional applications.
11. Run the validation checklist in this manual.

## 13. Maintenance Schedule

### Weekly

- review Uptime Kuma alerts;
- review containers with unhealthy or restarting states;
- check available storage;
- check failed backups;
- review Watchtower activity before accepting unexpected updates;
- inspect Cloudflare and Home Assistant authentication anomalies.

### Monthly

- apply host security updates during a maintenance window;
- review Docker image updates and release notes for stateful services;
- test one configuration restore;
- inspect certificate status;
- review inactive firewall, Cloudflare, and proxy rules;
- review repository changes not yet reflected in the live environment;
- verify UPS, SMART, and storage health where supported.

### Quarterly

- perform a database restore test;
- review administrator accounts and MFA;
- review exposed services and port forwards;
- audit secrets and revoke unused tokens;
- verify disaster-recovery documentation against the actual environment;
- update diagrams and dependency maps.

## 14. Change Management

Every significant change should include:

1. objective;
2. affected services;
3. prerequisites;
4. backup;
5. implementation;
6. validation;
7. rollback;
8. documentation;
9. Git commit.

Recommended Git workflow:

```bash
git pull --rebase
git status
git add <specific-files>
git commit -m "docs: describe the change"
git push
```

Preferred aliases, when configured:

```bash
gl
gs
gc "docs: describe the change"
gp
```

Do not use `git add -A` when unrelated work exists in the tree.

## 15. Incident Response

### 15.1 Initial triage

Record:

- exact symptom;
- first observed time;
- affected hostname or service;
- local versus remote impact;
- last known change;
- container state;
- relevant logs;
- available disk space;
- DNS result;
- proxy and tunnel state.

### 15.2 Severity guide

| Severity | Description | Example |
|---|---|---|
| SEV-1 | Security event, data-loss risk, or broad infrastructure outage | suspected compromise, failed storage pool |
| SEV-2 | Critical service unavailable with no workaround | Home Assistant, DNS, or remote access outage |
| SEV-3 | One service degraded or unavailable | Sonarr, Seerr, or a camera integration failure |
| SEV-4 | Cosmetic issue or planned improvement | dashboard layout or documentation correction |

### 15.3 Containment principles

- revoke or rotate exposed credentials;
- disable the narrowest affected ingress path;
- preserve logs before recreating containers;
- do not delete volumes during initial troubleshooting;
- isolate suspicious containers from external networks;
- document every emergency change after service is stable.

## 16. Validation Checklist

Run after major maintenance or recovery:

```text
[ ] NAS reachable on LAN
[ ] Tailscale reachable
[ ] Docker daemon healthy
[ ] Critical containers running
[ ] Pi-hole resolves public and local names
[ ] Unbound resolves recursively
[ ] Nginx Proxy Manager routes local hosts
[ ] Cloudflare Tunnel healthy
[ ] Home Assistant works locally and publicly
[ ] Home Assistant app connects
[ ] Eufy camera streams load
[ ] Home/Away automations function
[ ] Tesla telemetry updates
[ ] Plex local playback works
[ ] Plex remote access works where intentionally enabled
[ ] Gluetun VPN connected
[ ] qBittorrent egress uses VPN
[ ] Sonarr/Radarr/Prowlarr communicate
[ ] Seerr can reach media managers
[ ] Uptime Kuma monitors are green
[ ] Backup jobs completed
[ ] No unexpected authentication errors
```

## 17. Known Decisions and Deferred Work

- Cloudflare Tunnel is preferred over direct public port forwarding for web applications.
- Home Assistant remains accessible through both `ha.home` and `ha.armouredcore.net`.
- Cloudflare custom WAF rules are deferred until the desired matching and action controls are available.
- mTLS is deferred because of client compatibility and administrative overhead.
- Homebridge remains in use for Eufy export to Apple Home where it provides faster stream startup than the evaluated Home Assistant path.
- Watchtower should move toward explicit opt-in updates with stateful and critical services excluded from unattended changes.
- Backup jobs and restore tests require continued verification as the service inventory evolves.

## 18. Related Documentation

- [`../README.md`](../README.md)
- [`../DASHBOARD.md`](../DASHBOARD.md)
- [`../architecture/homelab-dependency-map.md`](../architecture/homelab-dependency-map.md)
- [`../docker/README.md`](../docker/README.md)
- [`../diagnostics/README.md`](../diagnostics/README.md)
- [`../services/home-assistant-eufy-cameras.md`](../services/home-assistant-eufy-cameras.md)
- [`../services/home-assistant-presence-security.md`](../services/home-assistant-presence-security.md)
- [`../services/home-assistant-tesla-dashboard.md`](../services/home-assistant-tesla-dashboard.md)

## 19. Review Record

| Date | Change |
|---|---|
| 2026-07-19 | Initial consolidated operations manual, including Cloudflare and Home Assistant security baseline, maintenance, backup, recovery, and incident procedures |
