# Portainer

## Purpose

Provides the web interface used to manage Docker containers and Portainer stacks on the UGREEN NAS.

## Deployment

- Container: `portainer`
- Image: `portainer/portainer-ce:latest`
- Ports: `8000` and `9000`
- Docker socket: `/var/run/docker.sock:/var/run/docker.sock`
- Persistent data: `/volume1/docker/portainer:/data`
- Networks: `portainer_default` and external `media-net`

## Deploy

This stack is host-managed rather than self-managed through Portainer:

```bash
cd /volume1/docker/portainer
docker compose up -d
```

## Verify

```bash
docker ps --filter name=portainer
docker logs --tail 100 portainer
curl -I http://127.0.0.1:9000
```

Back up `/volume1/docker/portainer` before upgrades or recovery work.