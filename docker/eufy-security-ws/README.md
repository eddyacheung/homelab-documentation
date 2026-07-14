# eufy-security-ws

## Purpose

`eufy-security-ws` provides the websocket backend used by the Home Assistant Eufy Security integration. It authenticates to the Eufy account, persists session state, and exposes the local websocket service consumed by Home Assistant.

## Deployment

- Image: `bropat/eufy-security-ws:latest`
- Container: `eufy-security-ws`
- Restart policy: `unless-stopped`
- Published endpoint: `127.0.0.1:3000`

The service is bound to loopback only. This limits direct access to the NAS itself and avoids exposing the websocket endpoint to the LAN.

## Required Variables

Copy `.env.example` to `.env` outside version control and provide real values:

| Variable | Purpose |
| --- | --- |
| `EUFY_USERNAME` | Eufy account email |
| `EUFY_PASSWORD` | Eufy account password |
| `EUFY_COUNTRY` | Account country code, currently `US` |
| `EUFY_LANGUAGE` | Preferred language, currently `en` |
| `EUFY_PERSISTENT` | Preserve authentication/session behavior across restarts |

Never commit the real `.env` file or Eufy credentials.

## Persistent Storage

| Host path | Container path | Purpose |
| --- | --- | --- |
| `/volume1/docker/eufy-security-ws/data` | `/data` | Authentication state and persistent service data |

## Updates

The container is explicitly excluded from Watchtower automatic updates:

```yaml
com.centurylinklabs.watchtower.enable: "false"
```

Update manually and verify authentication, camera entities, and live streams afterward.

## Deployment through Portainer

1. Create `/volume1/docker/eufy-security-ws/data` if it does not exist.
2. Create a private `.env` file from `.env.example`.
3. Deploy `docker-compose.yml` as a Portainer stack.
4. Confirm the service is running:

```bash
docker ps --filter name=eufy-security-ws
```

## Verification

Check logs for successful startup and authentication:

```bash
docker logs --tail 100 eufy-security-ws
```

Then verify in Home Assistant that:

- Eufy devices and entities are available.
- A powered indoor camera can provide a live stream.
- Outdoor or battery-optimized cameras provide snapshots or streams according to their power behavior.

## Dependencies

- Home Assistant Eufy Security integration
- Eufy account credentials
- go2rtc and WebRTC Camera for the low-latency Home Assistant dashboard path

## Recovery

1. Restore `/volume1/docker/eufy-security-ws/data` if available.
2. Recreate the private `.env` file.
3. Redeploy the Compose stack.
4. Reconnect or reload the Eufy Security integration in Home Assistant if required.
5. Validate camera entities, event sensors, and streams.
