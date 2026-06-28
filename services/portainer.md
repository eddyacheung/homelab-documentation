# Portainer

## Purpose

Portainer provides a web interface for managing Docker containers, networks, volumes, images, and Compose stacks on the UGREEN NAS.

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Container name:** `portainer`
- **Image:** `portainer/portainer-ce:latest`
- **Compose project / stack:** `portainer`
- **Compose directory on NAS:** `/volume1/docker/portainer`
- **Compose file:** `/volume1/docker/portainer/compose.yml`
- **Persistent data directory:** `/volume1/docker/portainer`
- **Docker socket mount:** `/var/run/docker.sock:/var/run/docker.sock`

## Access

| Service | Address |
| --- | --- |
| Portainer web UI | `http://NAS-IP:9000` |
| Edge Agent tunnel port | `8000` |
| Nginx Proxy Manager hostname | `portainer.home` |

Nginx Proxy Manager reaches Portainer by Docker DNS name:

```text
http://portainer:9000
```

## Docker Networks

Portainer is attached to:

- `portainer_default`
- `media-net`

The `media-net` attachment allows Nginx Proxy Manager to proxy Portainer by container name.

## Compose Configuration

Current important bind mounts:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - /volume1/docker/portainer:/data
```

The `/volume1/docker/portainer:/data` mount is important because this Portainer install stores its database and managed stack compose files directly under `/volume1/docker/portainer`.

Key paths:

```text
/volume1/docker/portainer/portainer.db
/volume1/docker/portainer/compose/
/volume1/docker/portainer/certs/
/volume1/docker/portainer/tls/
```

## Conversion to Docker Compose

Portainer was converted from a standalone Docker container to a Docker Compose managed deployment.

The existing deployment used:

- `/volume1/docker/portainer` mounted to `/data`
- `/var/run/docker.sock` mounted to `/var/run/docker.sock`
- published ports `8000:8000` and `9000:9000`

The Compose deployment preserved those settings so the existing Portainer database, stack metadata, and compose files remained available.

## Stack Editor Recovery

### Symptoms

After Portainer was converted to Compose, existing stacks were visible but the Stack Editor could not open compose files. Portainer displayed an error similar to:

```text
Could not get the contents of the file 'docker-compose.yml'
```

### Root Cause

The Portainer container was temporarily mounted with:

```yaml
- /volume1/docker/portainer/data:/data
```

That mount pointed Portainer at the wrong data directory. The real stack files were stored under:

```text
/volume1/docker/portainer/compose/
```

but Portainer was looking inside:

```text
/volume1/docker/portainer/data/compose/
```

The containers continued running, but Portainer could no longer access the stack compose files used by the editor.

### Resolution

The data mount was corrected to:

```yaml
- /volume1/docker/portainer:/data
```

After redeploying Portainer, the Stack Editor could open compose files again.

Verified by opening the Homarr stack editor and confirming its compose file loaded successfully.

## Verification Commands

Check Portainer mounts:

```bash
docker inspect portainer --format '
Mounts:
{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}
'
```

Expected mount:

```text
/volume1/docker/portainer -> /data
/var/run/docker.sock -> /var/run/docker.sock
```

Check stack compose files:

```bash
find /volume1/docker/portainer/compose -maxdepth 3 -type f -name "docker-compose.yml" -print
```

Check Portainer health:

```bash
docker ps --filter name=portainer
```

## Recovery / Rollback

Before making major Portainer changes, back up the full Portainer directory:

```bash
mkdir -p /volume1/docker/backups

tar -czvf /volume1/docker/backups/portainer-data-backup-$(date +%F-%H%M).tar.gz \
  /volume1/docker/portainer
```

If Compose deployment fails, recreate Portainer with the original persistent data mount:

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

## Lessons Learned

- Do not change Portainer's `/data` mount unless intentionally migrating all Portainer data.
- Portainer stack records can exist even when the backing compose files are missing or inaccessible.
- A container can be healthy while Portainer management features are partially broken.
- Validate Portainer migrations by checking both service availability and Stack Editor functionality.
- Back up Portainer before changing mounts, compose files, or deployment methods.
