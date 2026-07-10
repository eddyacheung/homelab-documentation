# Uptime Kuma

## Purpose

Uptime Kuma provides self-hosted availability monitoring for important homelab services.

It is used to quickly identify whether a service is unavailable, unhealthy, or unreachable from the NAS. Notifications are configured so outages can be surfaced without manually checking every container.

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Container name:** `uptime-kuma`
- **Deployment method:** Docker Compose via Portainer
- **Published port:** `3001:3001`
- **Local URL:** `http://192.168.10.101:3001`
- **Restart policy:** `unless-stopped`
- **Container health:** Docker health check enabled

The live Portainer stack remains the source of truth for the image tag, volume path, labels, and complete Compose configuration.

## Current Monitoring Scope

Uptime Kuma currently monitors core media services, including:

- Plex
- Radarr
- Sonarr
- Seerr

Additional infrastructure monitors can be added as services are standardized and their expected behavior is documented.

Potential future monitors include:

- Pi-hole
- Unbound
- Nginx Proxy Manager
- Cloudflare Tunnel
- Portainer
- qBittorrent through the Gluetun-published web interface
- Open WebUI
- Homebridge

## Monitor Types

Use the monitor type that most closely matches the service being tested.

### HTTP or HTTPS

Use for web interfaces and API endpoints.

Examples:

```text
http://192.168.10.101:7878
http://192.168.10.101:8989
http://192.168.10.101:5055
http://192.168.10.101:32400/web
```

A successful HTTP response confirms that the application is reachable, but it does not always prove every internal dependency is healthy.

### TCP Port

Use when only service-port availability needs to be confirmed.

Examples include DNS, database, or proxy ports that do not expose a suitable HTTP endpoint.

### Docker Container

Docker-level monitoring can confirm whether a container is running, but an application-level HTTP monitor is generally more useful because a running container may still have a broken application.

## Monitoring Guidance

Recommended defaults for normal homelab services:

- **Heartbeat interval:** 60 seconds
- **Retries:** 2 or 3 before declaring an outage
- **Retry interval:** 20 to 30 seconds
- **Request timeout:** 10 to 15 seconds

Avoid extremely aggressive polling unless a service requires it. Fast checks create extra noise and may produce alerts during routine container restarts or Portainer stack updates.

## Notifications

Notifications are configured in Uptime Kuma and should be attached to monitors that require outage awareness.

When creating or editing a monitor:

1. Select the appropriate notification provider.
2. Use the test-notification function.
3. Confirm both outage and recovery messages are received.
4. Avoid enabling repeated notifications so frequently that a prolonged outage creates alert fatigue.

Notification credentials and tokens must not be committed to this repository.

## Maintenance Windows

Expected downtime can occur during:

- Portainer stack redeployments
- Watchtower maintenance windows
- NAS reboots
- Network or UniFi maintenance
- Pi-hole and Unbound changes
- Gluetun and qBittorrent recovery testing

Pause affected monitors or create a maintenance window when performing planned work. This prevents expected restarts from being recorded as unexplained incidents.

## Verification Commands

Check container status:

```bash
docker ps --filter name=uptime-kuma
```

Check health status:

```bash
docker inspect uptime-kuma \
  --format 'Status={{.State.Status}} Health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}'
```

Check recent logs:

```bash
docker logs uptime-kuma --tail 100
```

Verify that the web interface responds from the NAS:

```bash
curl -I --max-time 10 http://127.0.0.1:3001
```

Verify the published port:

```bash
docker port uptime-kuma
```

## Backup and Recovery

Uptime Kuma stores its monitor definitions, history, users, and notification settings in its persistent application-data volume.

Before rebuilding or replacing the container:

1. Identify the live bind mount or named volume.
2. Stop Uptime Kuma cleanly.
3. Back up the complete persistent-data directory.
4. Verify that the backup contains the Uptime Kuma database and configuration data.
5. Record the currently deployed image tag and Compose configuration.

Typical recovery flow:

1. Restore the persistent-data directory to its original path.
2. Confirm ownership and permissions match the container requirements.
3. Redeploy the Portainer stack.
4. Confirm the dashboard loads.
5. Verify that monitors and notification providers are present.
6. Send a test notification.

Do not recreate Uptime Kuma without preserving its persistent data unless losing monitor history and configuration is acceptable.

## Troubleshooting

### Dashboard Is Unavailable

Verify:

- The `uptime-kuma` container is running.
- Port `3001` is published on the NAS.
- No other service is using port `3001`.
- The persistent-data volume is mounted correctly.
- Recent logs do not show database or permission errors.

Commands:

```bash
docker ps -a --filter name=uptime-kuma
docker logs uptime-kuma --tail 100
ss -lntp | grep ':3001'
```

### Monitor Shows Down but Service Works in a Browser

Check whether Uptime Kuma can reach the target from the NAS or container network, not only from the user's workstation.

Possible causes:

- The monitor uses an outdated IP address or port.
- The target container moved to a different Docker network.
- The service is reachable from the LAN but not from Uptime Kuma's network.
- Authentication, redirects, or certificate validation are affecting the check.
- Pi-hole or local DNS resolves the hostname differently inside Docker.

Test the target from the Uptime Kuma container when the required utility is available, or test from the NAS with `curl`.

### Notifications Do Not Arrive

Verify:

- The notification provider test succeeds.
- The notification is attached to the affected monitor.
- Credentials or tokens have not expired.
- The NAS has outbound internet and DNS access.
- The provider is not suppressing or rate-limiting messages.

### False Alerts During Updates

Increase retries or use a maintenance window. A short container recreation should not necessarily generate an outage notification.

## Security Notes

- Keep Uptime Kuma available only to trusted networks unless remote access is protected by an authenticated reverse proxy or Cloudflare Access.
- Do not publish notification tokens, webhook URLs, passwords, or exported configuration files.
- Treat the dashboard as administrative infrastructure because it reveals service names, addresses, ports, and availability history.

## Future Improvements

- Add monitors for DNS resolution through Pi-hole and Unbound.
- Add a qBittorrent web-interface monitor through Gluetun port `8888`.
- Add maintenance windows aligned with planned Watchtower activity.
- Document the notification provider and escalation behavior without exposing secrets.
- Confirm and document the exact image tag, persistent-data path, Docker network, and Watchtower policy from the live Portainer stack.
- Periodically test notification delivery and recovery alerts.

## Notes

Uptime Kuma is an observability tool, not an automatic repair system. It reports outages, while service-specific recovery mechanisms, such as the Gluetun and qBittorrent watchdog, handle remediation.
