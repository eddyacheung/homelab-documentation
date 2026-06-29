# Docker Networking

## Purpose

This document tracks the important Docker networks used by the homelab, why each network exists, and how containers should communicate with each other.

The goal is to avoid mystery networks, accidental service isolation, and future troubleshooting chaos when services are moved between Docker Compose, Portainer stacks, host networking, bridge networking, or macvlan.

---

## Current Network Strategy

The homelab uses a small number of intentional Docker network patterns:

| Network Type | Used For | Notes |
|--------------|----------|-------|
| Custom bridge | Most application containers | Preferred for normal container-to-container communication |
| Host network | Plex | Used when LAN discovery and media client compatibility matter |
| Macvlan | Pi-hole | Gives Pi-hole its own LAN IP |
| Default bridge | Temporary or legacy containers | Avoid for long-term service deployment when possible |

---

## Important Networks

### `media-net`

`media-net` is the primary shared Docker bridge network for the media stack.

Services that belong on `media-net` include:

- Sonarr
- Radarr
- Prowlarr
- qBittorrent
- Seerr / Overseerr
- Nginx Proxy Manager
- Portainer, when it needs to reach media services by container name

Why this matters:

- Containers can reach each other by container name.
- Nginx Proxy Manager can proxy to backend services without using NAS LAN IPs.
- The media stack stays grouped on one predictable network.

Example:

```text
http://sonarr:8989
http://radarr:7878
http://qbittorrent:8080
http://seerr:5055
```

---

### `ai-net`

`ai-net` is used for AI-related services.

Known services:

- Open WebUI
- Future AI/search/RAG services such as SearXNG or document indexing containers

Keep AI services separate from the media stack unless there is a clear reason to connect them.

---

### `pihole_macvlan`

`pihole_macvlan` is used for Pi-hole.

Pi-hole uses macvlan so it can have its own LAN IP address and function cleanly as a DNS server for selected network clients or VLANs.

This is intentional and should not be merged into `media-net`.

---

### `host`

The Docker `host` network is used intentionally by Plex.

Plex should remain on host networking because it improves compatibility with:

- Local client discovery
- Chromecast discovery
- DLNA behavior
- Plex apps on the LAN

Plex is one of the few services where host networking is preferred over a custom bridge.

---

## Plex and Host-Network Access

Plex runs with:

```yaml
network_mode: host
```

Because Plex is not attached to `media-net`, containers such as Sonarr and Radarr should not try to reach Plex by the container name `plex`.

Instead, containers on `media-net` should reach Plex through the Docker bridge gateway:

```text
http://172.26.0.1:32400
```

This was verified from inside the Sonarr container:

```bash
docker exec sonarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

Expected result:

```text
Plex XML identity response
```

The NAS LAN IP was avoided for this internal container-to-host path because the Docker bridge gateway provided the reliable route from `media-net` containers to host-networked Plex.

---

## `host.docker.internal`

`host.docker.internal` was not used for the media stack.

Reason:

- On Linux Docker hosts, `host.docker.internal` is not always available by default.
- The Docker bridge gateway IP was already known and verified.
- Using `172.26.0.1` keeps the configuration explicit and predictable for this environment.

Preferred internal Plex URL for Sonarr/Radarr:

```text
http://172.26.0.1:32400
```

---

## Network Cleanup

During the Plex auto-scan troubleshooting, unused Docker networks were audited and cleaned up.

The audit command used was:

```bash
docker network inspect $(docker network ls -q) --format '{{.Name}}: {{len .Containers}} containers'
```

Unused networks were removed with:

```bash
docker network prune
```

Only unused networks were removed. Active networks such as `media-net`, `ai-net`, `pihole_macvlan`, `host`, `bridge`, and `none` were intentionally preserved.

---

## When to Use Each Network Type

### Use `media-net` when

- The service is part of the media stack.
- Nginx Proxy Manager needs to proxy to it.
- Other media containers need to reach it by container name.

### Use `ai-net` when

- The service belongs to Open WebUI, Ollama integrations, SearXNG, or future RAG/document tooling.
- The service does not need to talk directly to the media stack.

### Use `host` when

- The service needs direct LAN discovery or broadcast behavior.
- The service is Plex.

Do not casually use host networking for normal services. It reduces isolation and makes port conflicts easier to create.

### Use `macvlan` when

- The service needs its own LAN IP address.
- The service acts like infrastructure on the network, such as DNS.

Pi-hole is the current example.

---

## Verification Commands

List Docker networks:

```bash
docker network ls
```

Show network membership counts:

```bash
docker network inspect $(docker network ls -q) --format '{{.Name}}: {{len .Containers}} containers'
```

Inspect a specific network:

```bash
docker network inspect media-net
```

Check which networks a container is attached to:

```bash
docker inspect sonarr --format '{{json .NetworkSettings.Networks}}'
```

Test container-to-container communication:

```bash
docker exec sonarr curl --connect-timeout 5 http://radarr:7878
```

Test container-to-host Plex communication:

```bash
docker exec sonarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

---

## Documentation Rules

When adding or moving containers:

1. Document which Docker network the service uses.
2. Document whether the service is reached by container name, NAS LAN IP, macvlan IP, or Docker bridge gateway.
3. If Nginx Proxy Manager proxies to the service, make sure NPM is on the same Docker network as the backend container.
4. Avoid creating one-off default Compose networks unless the service truly does not need to communicate with anything else.
5. Before pruning networks, verify container counts and preserve anything active.

---

## Lessons Learned

- Plex should stay on host networking for media client compatibility.
- Sonarr and Radarr should reach Plex through `172.26.0.1:32400` from `media-net`.
- Nginx Proxy Manager needs to share a Docker network with the services it proxies.
- Empty Docker networks can accumulate after Compose changes and stack migrations.
- Network cleanup should be audited before pruning.
- Documenting network intent prevents future mystery spaghetti.
