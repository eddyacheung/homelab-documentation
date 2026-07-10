# Nginx Proxy Manager

## Purpose

Provides local reverse-proxy routing and certificate management for homelab web services.

## Deployment

- Container: `nginx-proxy-manager`
- Image: `jc21/nginx-proxy-manager:latest`
- Ports: `80`, `443`, and admin port `8181`
- Networks: external `media-net` and `nginx-proxy-manager_default`
- Persistent data:
  - `/volume1/docker/nginx-proxy-manager/data:/data`
  - `/volume1/docker/nginx-proxy-manager/letsencrypt:/etc/letsencrypt`

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=nginx-proxy-manager
docker logs --tail 100 nginx-proxy-manager
curl -I http://127.0.0.1:8181
```

Back up both persistent directories before rebuilding or migrating the stack.