# Docker Networking Troubleshooting

## Overview

This document captures networking issues encountered while building and maintaining a Docker-based homelab on a UGREEN NAS.

Services involved:

* Sonarr
* Radarr
* Prowlarr
* qBittorrent
* Gluetun
* Seerr
* Portainer
* Open WebUI

---

## Problem: Containers Could Not Communicate

### Symptoms

* Sonarr could not connect to qBittorrent
* Radarr could not connect to qBittorrent
* Seerr experienced service connectivity issues
* Container hostname resolution failed

### Root Cause

Containers were attached to different Docker networks.

Docker DNS resolution only works automatically when containers share a common Docker network.

### Resolution

Moved related services to a shared Docker bridge network.

Verified communication using:

```bash
docker network inspect media-net
```

and

```bash
docker exec -it <container> ping <hostname>
```

### Lesson Learned

Containers must share a network for Docker DNS hostname resolution to work reliably.

---

## Problem: Seerr Database Connection Failure

### Symptoms

Seerr repeatedly failed to start.

Logs showed:

```text
getaddrinfo ENOTFOUND
```

### Root Cause

Database hostname in configuration did not match the actual container hostname.

### Resolution

Verified container names and updated the database host configuration.

Validated connectivity between containers on the same network.

### Lesson Learned

Container names, network names, and DNS resolution should always be verified when troubleshooting service startup issues.

---

## Problem: Host Network vs Bridge Network Confusion

### Symptoms

Services behaved differently depending on networking mode.

### Root Cause

Docker host networking bypasses Docker's internal DNS and networking features.

Bridge networking provides service isolation and hostname resolution.

### Resolution

Used bridge networking for most application containers.

Reserved host networking only when necessary.

### Lesson Learned

Understanding the differences between host and bridge networking is critical when troubleshooting container communication.

---

## Problem: Gluetun Fails With Empty OpenVPN User

### Symptoms

Gluetun starts and immediately exits or restarts.

Logs show:

```text
ERROR VPN settings: OpenVPN settings: user is empty
```

### Root Cause

The Compose file used variable interpolation that did not resolve correctly:

```yaml
- OPENVPN_USER=${NORDVPN_USER}
- OPENVPN_PASSWORD=${NORDVPN_PASS}
```

The `.env` file contained NordVPN-specific variable names, but Gluetun expects:

```text
OPENVPN_USER
OPENVPN_PASSWORD
```

### Resolution

Add Gluetun's expected variable names to:

```text
/volume1/docker/qbittorrent/.env
```

Expected names:

```text
OPENVPN_USER
OPENVPN_PASSWORD
```

Remove Compose interpolation lines and rely on:

```yaml
env_file:
  - /volume1/docker/qbittorrent/.env
```

Validate without printing secrets:

```bash
grep -E '^[A-Z_]+=' /volume1/docker/qbittorrent/.env | cut -d= -f1
```

### Lesson Learned

Use the exact environment variable names expected by the container image. Avoid Compose interpolation for secrets when an `env_file` can pass values directly into the container.

---

## Problem: qBittorrent Container Name Conflict During Migration

### Symptoms

Deploying the updated Gluetun + qBittorrent stack fails with:

```text
Conflict. The container name "/qbittorrent" is already in use
```

### Root Cause

The original qBittorrent container was still running with the same container name.

Docker cannot create a new container with the same name until the old one is removed.

### Resolution

Stop and remove only the old qBittorrent container:

```bash
docker stop qbittorrent
docker rm qbittorrent
```

Then redeploy the stack:

```bash
cd /volume1/docker/portainer/compose/38
docker compose up -d
```

This is safe when qBittorrent configuration and media paths are bind-mounted:

```text
/volume1/docker/qbittorrent/config
/volume2/Media
```

### Lesson Learned

Removing a container is not the same as deleting its persistent data. Verify bind mounts before removing a container during migration.

---

## Problem: Gluetun Port Already Allocated

### Symptoms

Starting Gluetun fails with:

```text
Bind for 0.0.0.0:8888 failed: port is already allocated
```

### Root Cause

The old qBittorrent container was still running and still owned port `8888`.

### Resolution

Stop and remove the old qBittorrent container before starting Gluetun as the new port owner:

```bash
docker stop qbittorrent
docker rm qbittorrent

cd /volume1/docker/portainer/compose/38
docker compose up -d
```

### Lesson Learned

When qBittorrent shares Gluetun's network namespace, published ports move from qBittorrent to Gluetun.

---

## Problem: qBittorrent WebUI Works Inside Container But Not From LAN

### Symptoms

qBittorrent logs show the WebUI is running:

```text
WebUI will be started shortly after internal preparations.
Connection to localhost (::1) 8888 port [tcp/*] succeeded!
```

Testing from inside the container succeeds:

```bash
docker exec qbittorrent curl -I http://127.0.0.1:8888
```

But testing from the NAS or LAN fails:

```bash
curl -I http://127.0.0.1:8888
```

Example failure:

```text
Recv failure: Connection reset by peer
```

### Root Cause

Gluetun's firewall was enabled and blocking inbound access to qBittorrent's WebUI.

Because qBittorrent shares Gluetun's network namespace, Gluetun owns the published port and its firewall controls inbound access.

### Resolution

Add the required inbound ports to Gluetun:

```text
FIREWALL_INPUT_PORTS=8888,6888
```

Restart the stack:

```bash
cd /volume1/docker/portainer/compose/38
docker compose down
docker compose up -d
```

Validate:

```bash
curl -I http://127.0.0.1:8888
```

Expected:

```text
HTTP/1.1 200 OK
```

### Lesson Learned

When Gluetun firewall is enabled, published ports still need to be explicitly allowed with `FIREWALL_INPUT_PORTS`.

---

## Problem: qBittorrent Has Internet Without Gluetun

### Symptoms

After VPN migration, qBittorrent still appears to have internet when Gluetun is stopped.

### Root Cause

This would indicate qBittorrent is not actually using Gluetun's network namespace.

Likely causes:

* `network_mode: "service:gluetun"` is missing
* qBittorrent is still running as an old standalone container
* The old container was not removed before redeploying

### Resolution

Check the running containers:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "gluetun|qbittorrent"
```

Verify qBittorrent public IP:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

Kill switch test:

```bash
docker stop gluetun
docker exec qbittorrent curl -m 10 -s https://ipinfo.io/ip || echo "No internet from qbittorrent"
```

Expected:

```text
No internet from qbittorrent
```

Restart:

```bash
cd /volume1/docker/portainer/compose/38
docker compose up -d
```

### Lesson Learned

Always test kill switch behavior after changing VPN routing. Do not assume the design works just because the containers are running.

---

## Useful Commands

View container networks:

```bash
docker network ls
```

Inspect network:

```bash
docker network inspect media-net
```

View running containers:

```bash
docker ps
```

Check logs:

```bash
docker logs <container>
```

Enter container shell:

```bash
docker exec -it <container> bash
```

Test DNS resolution:

```bash
ping <container-name>
```

Check Gluetun logs:

```bash
docker logs gluetun --tail=80
```

Check qBittorrent WebUI:

```bash
curl -I http://127.0.0.1:8888
```

Check qBittorrent public IP:

```bash
docker exec qbittorrent curl -s https://ipinfo.io/ip
```

---

## Key Takeaways

* Docker DNS depends on shared networks.
* Host and bridge networking behave differently.
* Container names are frequently used as hostnames.
* Network design should be planned before large deployments.
* qBittorrent behind Gluetun uses a shared network namespace, not normal bridge networking.
* Gluetun's firewall can block published WebUI ports unless `FIREWALL_INPUT_PORTS` is configured.
* VPN kill switches should be tested directly after deployment.
* Troubleshooting is easier when services are grouped logically on shared networks.
