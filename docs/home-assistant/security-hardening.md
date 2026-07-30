# Home Assistant Security Hardening

## Overview

Home Assistant runs as a Docker container on the UGREEN NAS using host networking. The container previously mounted the Docker socket directly for the `monitor_docker` custom integration.

Even when mounted with `:ro`, access to `/var/run/docker.sock` still permits Docker API calls and can effectively provide host-level control. The direct socket mount was removed and replaced with a restricted Docker Socket Proxy.

## Final Architecture

```text
Home Assistant
  -> http://127.0.0.1:2375
  -> docker-socket-proxy
  -> /var/run/docker.sock
```

The proxy is bound only to the NAS loopback interface and permits read-only monitoring endpoints while blocking Docker API write operations.

## Home Assistant Stack

Portainer stack: `homeassistant`

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    hostname: homeassistant
    network_mode: host
    restart: unless-stopped

    security_opt:
      - no-new-privileges:true

    environment:
      TZ: America/Chicago

    volumes:
      - /volume1/docker/homeassistant/config:/config
      - /volume2:/ugreen-volume2:ro
      - /etc/localtime:/etc/localtime:ro

    labels:
      - "com.centurylinklabs.watchtower.enable=true"
      - "com.centurylinklabs.watchtower.monitor-only=true"

  docker-socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    container_name: docker-socket-proxy
    restart: unless-stopped

    ports:
      - "127.0.0.1:2375:2375"

    environment:
      CONTAINERS: "1"
      EVENTS: "1"
      INFO: "1"
      PING: "1"
      VERSION: "1"

      POST: "0"
      AUTH: "0"
      BUILD: "0"
      COMMIT: "0"
      CONFIGS: "0"
      DISTRIBUTION: "0"
      EXEC: "0"
      IMAGES: "0"
      NETWORKS: "0"
      NODES: "0"
      PLUGINS: "0"
      SECRETS: "0"
      SERVICES: "0"
      SESSION: "0"
      SWARM: "0"
      SYSTEM: "0"
      TASKS: "0"
      VOLUMES: "0"

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

    security_opt:
      - no-new-privileges:true

    read_only: true

    tmpfs:
      - /run
      - /tmp

    labels:
      - "com.centurylinklabs.watchtower.enable=true"
      - "com.centurylinklabs.watchtower.monitor-only=true"
```

## Home Assistant Configuration

The `monitor_docker` integration was changed from the Unix socket:

```yaml
url: unix:///var/run/docker.sock
```

to the loopback-only proxy:

```yaml
url: http://127.0.0.1:2375
```

Configuration file:

```text
/volume1/docker/homeassistant/config/configuration.yaml
```

## Verification

Confirm Home Assistant has no direct socket mount and is not privileged:

```bash
docker inspect homeassistant \
  --format 'SecurityOpt={{json .HostConfig.SecurityOpt}}
Privileged={{.HostConfig.Privileged}}
Socket={{range .Mounts}}{{if eq .Destination "/var/run/docker.sock"}}PRESENT{{end}}{{end}}'
```

Expected result:

```text
SecurityOpt=["no-new-privileges:true"]
Privileged=false
Socket=
```

Confirm the proxy is running and bound only to loopback:

```bash
docker ps --filter name=docker-socket-proxy
ss -lntp | grep 2375
```

Expected listener:

```text
127.0.0.1:2375
```

Confirm permitted read access:

```bash
curl -v --max-time 10 http://127.0.0.1:2375/_ping
```

Expected response:

```text
HTTP/1.1 200 OK
```

Confirm write operations are blocked:

```bash
curl -i -X POST \
  http://127.0.0.1:2375/containers/homeassistant/restart
```

Expected response:

```text
HTTP/1.0 403 Forbidden
Request forbidden by administrative rules.
```

Confirm the dashboard Docker telemetry still works:

- Container count is populated.
- CPU and memory readings are populated.
- Home Assistant, Portainer, Plex, and Pi-hole report their actual states.

## Security Result

The final state provides:

- No direct Docker socket access from Home Assistant.
- `no-new-privileges` enabled for Home Assistant and the socket proxy.
- Home Assistant running with `Privileged=false`.
- Docker API exposed only on `127.0.0.1:2375`.
- Monitoring endpoints enabled.
- Docker API write requests blocked with HTTP 403.
- Existing Home Assistant Docker telemetry preserved.

## Operational Notes

- Do not expose port `2375` on `0.0.0.0` or the LAN.
- Do not restore `/var/run/docker.sock` to the Home Assistant container.
- Keep `POST=0` unless there is a deliberate requirement for Home Assistant to control containers.
- Do not commit HomeKit pairing codes, access tokens, API keys, passwords, or other secrets to this repository.
- After changing the proxy permissions, retest both `/_ping` and the blocked restart request.
