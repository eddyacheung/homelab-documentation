[200~# Nginx Proxy Manager

## Purpose

Nginx Proxy Manager provides reverse proxy functionality for homelab services using a web-based management interface.

## Deployment

- Platform: UGREEN NAS
- Deployment Method: Docker Compose via Portainer
- Container: jc21/nginx-proxy-manager

## Ports

| Host Port | Container Port | Purpose |
|------------|------------|------------|
| 8081 | 80 | HTTP Proxy |
| 8181 | 81 | NPM Admin Interface |
| 4443 | 443 | HTTPS Proxy |

## Initial Configuration

### Proxy Hosts

#### Seerr

Domain:
- seerr.home

Forward Target:
- ugreen:5055

Settings:
- Cache Assets: Disabled
- Block Common Exploits: Disabled
- Websockets Support: Enabled

## Future Plans

- Integrate with Pi-hole local DNS
- Add Open WebUI proxy host
- Add Homarr proxy host
- Evaluate Cloudflare Tunnel
- Configure armouredcore.net subdomains
