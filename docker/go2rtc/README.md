# go2rtc

## Purpose

go2rtc provides the low-latency camera stream relay used by Home Assistant and the WebRTC Camera integration for Eufy camera viewing.

## Deployment

- Image: `alexxit/go2rtc:latest`
- Container: `go2rtc`
- Restart policy: `unless-stopped`
- Network mode: `host`
- Time zone: `America/Chicago`

Host networking is used so Home Assistant and local camera integrations can reach go2rtc services directly without extra Docker port translation.

## Persistent Storage

| Host path | Container path | Purpose |
| --- | --- | --- |
| `/volume1/docker/go2rtc/config` | `/config` | go2rtc configuration and persistent state |

## Updates

The container is explicitly excluded from Watchtower automatic updates:

```yaml
com.centurylinklabs.watchtower.enable: "false"
```

Update it manually during a maintenance window and validate camera streams afterward.

## Deployment through Portainer

1. Create or update the Portainer stack using `docker-compose.yml` from this directory.
2. Confirm `/volume1/docker/go2rtc/config` exists.
3. Deploy the stack.
4. Confirm the container is running:

```bash
docker ps --filter name=go2rtc
```

## Verification

Check recent logs:

```bash
docker logs --tail 100 go2rtc
```

Confirm a known camera stream loads in Home Assistant through the WebRTC camera card.

## Dependencies

- Home Assistant
- WebRTC Camera integration
- Eufy Security integration
- `eufy-security-ws`

## Recovery

1. Restore `/volume1/docker/go2rtc/config` from backup if needed.
2. Redeploy the Compose file.
3. Confirm Home Assistant can reconnect to the stream relay.
4. Re-test at least one powered camera and one battery-optimized camera.
