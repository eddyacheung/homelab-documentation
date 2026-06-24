# Portainer

## Purpose

Portainer provides a web interface for managing Docker containers, networks, volumes, images, and Compose stacks on the UGREEN NAS.

## Deployment

* **Host:** UGREEN DXP4800 Plus
* **Container name:** `portainer`
* **Image:** `portainer/portainer-ce:latest`
* **Compose project / stack:** `portainer`
* **Compose directory on NAS:** `/volume1/docker/portainer`
* **Persistent data directory:** `/volume1/docker/portainer`
* **Docker socket mount:** `/var/run/docker.sock:/var/run/docker.sock`

## Access

| Service                | Address              |
| ---------------------- | -------------------- |
| Portainer web UI       | `http://NAS-IP:9000` |
| Edge Agent tunnel port | `8000`               |

> Port `9443` is exposed internally by the image but is not published on the NAS. Portainer is currently accessed over HTTP on port `9000`.

## Compose File

File location on NAS:

```text
/volume1/docker/portainer/compose.yml
```

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "8000:8000"
      - "9000:9000"
    volumes:
      - /volume1/docker/portainer:/data
      - /var/run/docker.sock:/var/run/docker.sock
```

## Conversion to Docker Compose

Portainer was originally created with a direct `docker run` command, so it appeared only in the Docker container list and not as a Compose stack.

It was converted to Docker Compose while preserving the existing Portainer configuration and data.

### Existing configuration discovered

```bash
docker inspect portainer --format '{{json .Mounts}}'
docker inspect portainer --format '{{json .HostConfig.PortBindings}}'
```

The existing deployment used bind mounts:

* `/volume1/docker/portainer` mounted to `/data`
* `/var/run/docker.sock` mounted to `/var/run/docker.sock`

Published ports:

* `8000:8000`
* `9000:9000`

### Conversion procedure

1. Created `/volume1/docker/portainer/compose.yml`.
2. Matched the existing image, ports, restart policy, and bind mounts.
3. Stopped and removed only the old Portainer container:

```bash
docker stop portainer
docker rm portainer
```

4. Recreated Portainer through Docker Compose:

```bash
cd /volume1/docker/portainer
docker compose up -d
```

5. Verified that the container was now Compose-managed:

```bash
docker inspect portainer --format '{{ index .Config.Labels "com.docker.compose.project" }}'
```

Expected output:

```text
portainer
```

## Management Commands

Run these from `/volume1/docker/portainer`:

```bash
docker compose ps
docker compose logs -f
docker compose pull
docker compose up -d
docker compose down
```

> Avoid `docker compose down -v` because `-v` can remove Docker-managed volumes. Portainer currently uses bind-mounted persistent storage, but avoiding `-v` is a good general habit.

## Recovery / Rollback

If Compose deployment fails, recreate Portainer with:

```bash
docker run -d \
  --name portainer \
  --restart=unless-stopped \
  -p 8000:8000 \
  -p 9000:9000 \
  -v /volume1/docker/portainer:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce:latest
```

This reuses the existing persistent data directory and restores the prior deployment method.


