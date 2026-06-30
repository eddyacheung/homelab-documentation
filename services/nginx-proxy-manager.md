# Nginx Proxy Manager

## Purpose

Nginx Proxy Manager (NPM) provides reverse proxy functionality for homelab services using a web-based management interface. It allows services to be accessed using friendly hostnames instead of IP addresses and ports.

Example:

* `seerr.home`
* `sonarr.home`
* `radarr.home`
* `prowlarr.home`
* `qbt.home`

Instead of:

* `192.168.10.101:5055`
* `192.168.10.101:8989`
* `192.168.10.101:7878`
* `192.168.10.101:9696`
* `192.168.10.101:8888`

## Deployment

* Platform: UGREEN NAS
* Deployment Method: Docker Compose via Portainer
* Container Image: `jc21/nginx-proxy-manager`
* Network: `media-net`

## Ports

| Host Port | Container Port | Purpose             |
| --------- | -------------- | ------------------- |
| 8081      | 80             | HTTP Proxy          |
| 8181      | 81             | NPM Admin Interface |
| 4443      | 443            | HTTPS Proxy         |

## Initial Configuration

1. Deploy NPM using Portainer.
2. Configure persistent storage for NPM data.
3. Access the admin interface:

   * `http://npm.home:8181`
   * `http://192.168.10.101:8181`
4. Change the default administrator password.
5. Verify NPM is operational before creating proxy hosts.

## Local DNS Integration

### Core Infrastructure

| Hostname        | Target         |
| --------------- | -------------- |
| npm.home        | 192.168.10.101 |
| portainer.home  | 192.168.10.101 |
| openwebui.home  | 192.168.10.101 |
| homarr.home     | 192.168.10.101 |
| homebridge.home | 192.168.10.101 |

### Media Services

| Hostname      | Target         |
| ------------- | -------------- |
| seerr.home    | 192.168.10.101 |
| sonarr.home   | 192.168.10.101 |
| radarr.home   | 192.168.10.101 |
| prowlarr.home | 192.168.10.101 |
| qbt.home      | 192.168.10.101 |

## Docker Networking

Nginx Proxy Manager must be attached to the same Docker network as the services it proxies.

Current network:

* `media-net`

This allows NPM to communicate directly with application containers.

## Proxy Host Configuration

### Portainer

| Setting | Value |
|---|---|
| Domain | portainer.home |
| Forward Hostname/IP | portainer |
| Forward Port | 9000 |
| Scheme | http |
| Docker Network | portainer bridge network |

### Seerr

| Setting             | Value      |
| ------------------- | ---------- |
| Domain              | seerr.home |
| Forward Hostname/IP | seerr      |
| Forward Port        | 5055       |

### Sonarr

| Setting             | Value       |
| ------------------- | ----------- |
| Domain              | sonarr.home |
| Forward Hostname/IP | sonarr      |
| Forward Port        | 8989        |

### Radarr

| Setting             | Value       |
| ------------------- | ----------- |
| Domain              | radarr.home |
| Forward Hostname/IP | radarr      |
| Forward Port        | 7878        |

### Prowlarr

| Setting             | Value         |
| ------------------- | ------------- |
| Domain              | prowlarr.home |
| Forward Hostname/IP | prowlarr      |
| Forward Port        | 9696          |

### qBittorrent

| Setting             | Value       |
| ------------------- | ----------- |
| Domain              | qbt.home    |
| Forward Hostname/IP | qbittorrent |
| Forward Port        | 8888        |

## Cloudflare Tunnel Integration

Nginx Proxy Manager remains the internal reverse proxy for selected public services published through Cloudflare Tunnel.

External traffic flow:

```text
Cloudflare
    |
    v
Cloudflare Tunnel
    |
    v
http://nginx-proxy-manager:80
    |
    v
NPM Proxy Host
    |
    v
Internal Docker Service
```

Example for Seerr:

| Layer | Value |
|---|---|
| Public URL | `https://seerr.armouredcore.net` |
| Cloudflare tunnel destination | `http://nginx-proxy-manager:80` |
| NPM proxy host | `seerr.armouredcore.net` |
| NPM forward host | `seerr` |
| NPM forward port | `5055` |

Cloudflare handles public HTTPS and Google authentication. NPM routes the request to the correct backend container.

Current approach:

- Keep `.home` hostnames for LAN-only access.
- Use `*.armouredcore.net` hostnames for selected Cloudflare-protected services.
- Protect public applications with Cloudflare Access before exposing the application login page.

## Troubleshooting

### Wrong Forward Port

A proxy host can be online while the backend still fails if the Forward Port does not match the application’s internal container port.

For Portainer:

- NPM external HTTP listener: `8081`
- Portainer internal HTTP port: `9000`
- These are different ports with different jobs.

### 502 Bad Gateway

#### Symptoms

* Proxy host appears online
* Browser returns 502 Bad Gateway
* Direct access to service works

#### Cause

NPM cannot communicate with the backend service.

#### Resolution

1. Verify NPM is attached to `media-net`
2. Verify the target container is attached to `media-net`
3. Verify the Forward Hostname/IP matches the Docker container name
4. Verify the Forward Port matches the application's internal port

#### Common Mistakes

Incorrect:

```text
192.168.10.101:5055
qbt:8888
```

Correct:

```text
seerr:5055
qbittorrent:8888
```

### Container Name Mismatch

Proxy hosts must reference the actual Docker container name.

| Service     | Container Name |
| ----------- | -------------- |
| Seerr       | seerr          |
| Sonarr      | sonarr         |
| Radarr      | radarr         |
| Prowlarr    | prowlarr       |
| qBittorrent | qbittorrent    |

### Cloudflare Tunnel 502 or Blank Page

If a Cloudflare-protected hostname fails but the `.home` hostname works:

1. Confirm the Cloudflare Tunnel is Healthy.
2. Confirm the published application route points to `nginx-proxy-manager:80`.
3. Confirm `cloudflared` and NPM share the same Docker network.
4. Confirm the NPM public proxy host uses the public hostname, such as `seerr.armouredcore.net`.
5. Confirm the NPM proxy host points to the correct internal container and port.

## Lessons Learned

* NPM must be attached to `media-net` to communicate with backend containers.
* Docker container names should be used as the Forward Hostname/IP whenever possible.
* Direct access to a service does not guarantee NPM can reach it.
* NPM logs are the fastest way to diagnose 502 Bad Gateway errors.
* Pi-hole local DNS and Docker networking should be validated separately when troubleshooting.
* Cloudflare Access should protect public application hostnames before traffic reaches NPM.

## Future Plans

* Move NPM from testing ports (8081/8181/4443) to standard ports (80/81/443)
* Enable HTTPS for internal services
* Continue integrating selected services with Cloudflare Tunnel
* Configure SSL certificates for internal-only services if needed
* Evaluate wildcard certificates
* Publish selected services externally through Cloudflare Tunnel
