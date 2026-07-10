# Homelab Dependency Map

This page provides a quick visual model of how the major services relate to one another. It is intentionally simplified and should be updated when networks, ingress paths, or service dependencies change.

## External Access and Application Flow

```mermaid
flowchart TD
    Internet[Internet]
    Cloudflare[Cloudflare]
    Tunnel[cloudflared]
    NPM[Nginx Proxy Manager]
    Seerr[Seerr]
    OpenWebUI[Open WebUI]
    Plex[Plex]

    Internet --> Cloudflare
    Cloudflare --> Tunnel
    Tunnel --> NPM
    NPM --> Seerr
    NPM --> OpenWebUI
    Plex --> Internet
```

Cloudflare Tunnel provides authenticated ingress for selected services. Plex currently uses its own remote-access path and is intentionally shown separately.

## Media Automation Flow

```mermaid
flowchart LR
    User[User]
    Seerr[Seerr]
    Radarr[Radarr]
    Sonarr[Sonarr]
    Prowlarr[Prowlarr]
    QB[qBittorrent]
    Gluetun[Gluetun / VPN]
    Unpackerr[Unpackerr]
    Media[(Media storage)]
    Plex[Plex]
    Recyclarr[Recyclarr]

    User --> Seerr
    Seerr --> Radarr
    Seerr --> Sonarr
    Radarr --> Prowlarr
    Sonarr --> Prowlarr
    Radarr --> QB
    Sonarr --> QB
    QB --> Gluetun
    QB --> Media
    Unpackerr --> QB
    Unpackerr --> Radarr
    Unpackerr --> Sonarr
    Radarr --> Media
    Sonarr --> Media
    Media --> Plex
    Recyclarr --> Radarr
    Recyclarr --> Sonarr
```

qBittorrent shares Gluetun's network namespace, so both containers must be treated as a coupled unit during updates and recovery.

## DNS and Local Networking

```mermaid
flowchart TD
    Clients[LAN clients]
    PiHole[Pi-hole]
    Unbound[Unbound]
    InternetDNS[Authoritative DNS hierarchy]
    MediaNet[media-net]
    AINet[ai-net]
    Macvlan[pihole_macvlan]

    Clients --> PiHole
    PiHole --> Unbound
    Unbound --> InternetDNS
    PiHole --- Macvlan
    Unbound --- MediaNet
    MediaNet --- AINet
```

The network boxes represent logical Docker connectivity, not unrestricted routing between every attached service.

## Operations and Monitoring

```mermaid
flowchart LR
    Portainer[Portainer]
    Docker[Docker Engine]
    Watchtower[Watchtower]
    Kuma[Uptime Kuma]
    Services[Managed services]
    Git[GitHub repository]

    Git --> Portainer
    Portainer --> Docker
    Docker --> Services
    Watchtower --> Docker
    Kuma --> Services
```

Git is the intended configuration source, Portainer is the deployment interface, Watchtower updates only explicitly labeled containers, and Uptime Kuma observes service availability.

## Maintenance Notes

- Update this map after adding a major service, network, database, or ingress path.
- Keep sensitive hostnames, credentials, and tunnel tokens out of diagrams.
- Use the individual stack READMEs and service documentation for exact ports, mounts, and recovery procedures.
