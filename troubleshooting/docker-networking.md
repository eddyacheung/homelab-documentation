# Docker Networking Troubleshooting

## Overview

This document captures networking issues encountered while building and maintaining a Docker-based homelab on a UGREEN NAS.

Services involved:

* Sonarr
* Radarr
* Prowlarr
* qBittorrent
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

---

## Key Takeaways

* Docker DNS depends on shared networks.
* Host and bridge networking behave differently.
* Container names are frequently used as hostnames.
* Network design should be planned before large deployments.
* Troubleshooting is easier when services are grouped logically on shared networks.
