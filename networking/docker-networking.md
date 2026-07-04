# Docker Networking

## Purpose

This document tracks the important Docker networks used by the homelab, why each network exists, and how containers should communicate with each other.

The goal is to avoid mystery networks, accidental service isolation, and future troubleshooting chaos when services are moved between Docker Compose, Portainer stacks, host networking, bridge networking, macvlan, or VPN gateway patterns.

---

## Current Network Strategy

The homelab uses a small number of intentional Docker network patterns:

| Network Type | Used For | Notes |
|--------------|----------|-------|
| Custom bridge | Most application containers | Preferred for normal container-to-container communication |
| Shared network namespace | qBittorrent behind Gluetun | Used to force qBittorrent through the VPN gateway |
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
- Seerr / Overseerr
- Nginx Proxy Manager
- Portainer, when it needs to reach media services by container name
- Gluetun, as the VPN gateway for qBittorrent

qBittorrent does not attach directly to `media-net` anymore. It shares Gluetun's network namespace using:

```yaml
network_mode: "service:gluetun"
```

Why this matters:

- Containers can reach each other by container name when they share `media-net`.
- Nginx Proxy Manager can proxy to backend services without using NAS LAN IPs.
- The media stack stays grouped on one predictable network.
- qBittorrent is forced through Gluetun instead of using a normal bridge network path.

Example:

```text
http://sonarr:8989
http://radarr:7878
http://seerr:5055
```

For qBittorrent, access the WebUI through Gluetun's published port:

```text
http://NAS-IP:8888
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

Important behavior:

- LAN clients can reach Pi-hole at `192.168.10.250`.
- The Docker host cannot directly reach its own macvlan container by default.
- The UGREEN NAS host requires the `pihole-shim` macvlan interface to reach Pi-hole from the host.
- Without the shim, UGOS `dnsmasq` forwarding to Pi-hole times out.

Related troubleshooting page:

```text
troubleshooting/ugos-host-dnsmasq-forwarding.md
```

---

## Host Access to macvlan Containers

Docker macvlan intentionally isolates the Docker host from containers attached to the macvlan network.

For Pi-hole, this means:

```text
LAN clients -> 192.168.10.250: works
UGOS host  -> 192.168.10.250: fails without shim
```

The host-side shim uses:

```text
Interface: pihole-shim
Shim IP:   192.168.10.249/32
Route:     192.168.10.250/32 dev pihole-shim
Parent:    eth0
```

The persistent service is:

```text
pihole-shim.service
```

Verification commands:

```bash
ip addr show pihole-shim
ip route | grep 192.168.10.250
ping -c 4 192.168.10.250
dig google.com @127.0.0.1
```

Expected results:

```text
pihole-shim@eth0
192.168.10.250 dev pihole-shim scope link
0% packet loss
SERVER: 127.0.0.1#53
status: NOERROR
```

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

## Gluetun and qBittorrent VPN Gateway

qBittorrent now routes through Gluetun instead of using an application-level SOCKS5 proxy.

Stack pattern:

```text
qBittorrent
    |
    v
Gluetun
    |
    v
NordVPN OpenVPN tunnel
    |
    v
Internet
```

Compose pattern:

```yaml
services:
  gluetun:
    networks:
      - media-net
    ports:
      - "8888:8888"
      - "6888:6888"
      - "6888:6888/udp"

  qbittorrent:
    network_mode: "service:gluetun"
```

Important behavior:

- qBittorrent shares Gluetun's network namespace.
- qBittorrent does not publish its own ports directly.
- qBittorrent WebUI is exposed through Gluetun on port `8888`.
- Torrent ports are exposed through Gluetun on `6888/tcp` and `6888/udp`.
- If Gluetun stops, qBittorrent loses internet access.

Gluetun firewall must allow inbound ports required by qBittorrent:

```text
FIREWALL_INPUT_PORTS=8888,6888
```

Without this setting, the qBittorrent WebUI can be reachable from inside the shared namespace but blocked or reset from the NAS / LAN.

---

## Plex and Host-Network Access

Plex runs with:

```yaml
network_mode: host
```

Because Plex is not attached to `media-net`, containers such as Sonarr and Radarr should not try to reach Plex by the container name `plex`.

On the UGREEN NAS, containers attached to the `media-net` bridge network should also avoid using the NAS LAN IP when they need to reach host-networked services. The NAS host itself can reach Plex through the LAN IP, but containers on `media-net` may time out when trying to hairpin back to the NAS LAN address.

Example that worked from the NAS host:

```bash
curl --connect-timeout 5 http://192.168.10.101:32400/identity
```

Example that timed out from inside Radarr:

```bash
docker exec radarr curl --connect-timeout 5 http://192.168.10.101:32400/identity
```

Instead, containers on `media-net` should reach Plex through the Docker bridge gateway:

```text
http://172.26.0.1:32400
```

This was verified from inside Radarr:

```bash
docker exec radarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

Expected result:

```text
Plex XML identity response
```

Use this value for Plex Connect integrations in Radarr and Sonarr:

```text
Host: 172.26.0.1
Port: 32400
Use SSL: unchecked
URL Base: blank
```

The key lesson is that `172.26.0.1` is the Docker bridge gateway for `media-net`, which gives containers a reliable path back to host-networked Plex.

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
- The service is a gateway container, such as Gluetun, that must expose ports for a protected app.

### Use `network_mode: service:<container>` when

- One container must share another container's network namespace.
- A protected app should be forced through a VPN gateway container.
- Kill switch behavior is desired.

Current example:

```yaml
network_mode: "service:gluetun"
```

Used by:

```text
qBittorrent -> Gluetun
```

Do not use this pattern casually. It means the protected container no longer has its own independent Docker network identity or port mappings.

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

When the Docker host itself must reach a macvlan container, create and document a host-side macvlan shim instead of assuming normal LAN routing will work.

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

Test host-to-Plex communication from the NAS:

```bash
curl --connect-timeout 5 http://192.168.10.101:32400/identity
```

Test container-to-host Plex communication through the Docker bridge gateway:

```bash
docker exec sonarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
docker exec radarr curl --connect-timeout 5 http://172.26.0.1:32400/identity
```

If the NAS host can reach `192.168.10.101:32400` but a container times out to that same address, use `172.26.0.1:32400` for the container-side Plex integration.

Check Gluetun and qBittorrent status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "gluetun|qbittorrent"
```

Check qBittorrent public IP from inside the protected namespace:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

Test qBittorrent WebUI through Gluetun:

```bash
curl -I http://127.0.0.1:8888
```

Test kill switch behavior:

```bash
docker stop gluetun
docker exec qbittorrent curl -m 10 -s https://ipinfo.io/ip || echo "No internet from qbittorrent"
```

Restart after kill switch test:

```bash
cd /volume1/docker/portainer/compose/38
docker compose up -d
```

---

## Documentation Rules

When adding or moving containers:

1. Document which Docker network the service uses.
2. Document whether the service is reached by container name, NAS LAN IP, macvlan IP, Docker bridge gateway, or shared network namespace.
3. If Nginx Proxy Manager proxies to the service, make sure NPM is on the same Docker network as the backend container.
4. If a container is protected by a VPN gateway, document the gateway container and kill switch behavior.
5. Avoid creating one-off default Compose networks unless the service truly does not need to communicate with anything else.
6. Before pruning networks, verify container counts and preserve anything active.
7. For macvlan containers, document whether the Docker host needs a shim interface to reach them.

---

## Lessons Learned

- Plex should stay on host networking for media client compatibility.
- Sonarr and Radarr should reach Plex through `172.26.0.1:32400` from `media-net`.
- On the UGREEN NAS, containers on `media-net` may time out when using the NAS LAN IP to reach host-networked Plex; use the Docker bridge gateway instead.
- Nginx Proxy Manager needs to share a Docker network with the services it proxies.
- qBittorrent should route through Gluetun using `network_mode: service:gluetun` instead of an application-level SOCKS5 proxy.
- Gluetun must expose qBittorrent WebUI and torrent ports when qBittorrent shares its network namespace.
- Empty Docker networks can accumulate after Compose changes and stack migrations.
- Network cleanup should be audited before pruning.
- Docker macvlan isolates the host from macvlan containers; Pi-hole requires the `pihole-shim` interface for UGOS host DNS forwarding.
- Documenting network intent prevents future mystery spaghetti.
