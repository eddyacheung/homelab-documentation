# Home Assistant Apple TV Integration

> Last updated: 2026-07-14

## Purpose

Document discovery, pairing, validation, and security settings for Apple TV devices integrated with Home Assistant Container.

## Environment

- Home Assistant Container on the UGREEN DXP4800 Plus
- Home Assistant using Docker host networking
- Apple TV integration backed by `pyatv`
- UniFi network with multicast discovery functioning

## Integrated Devices

- Bedroom Apple TV 4K (2nd generation)
- Game Room Apple TV 4K (3rd generation)

Both devices were discovered automatically by Home Assistant through Bonjour/mDNS.

## Initial Problem

Home Assistant discovered the Apple TVs but setup failed with authentication errors.

Relevant log signatures included:

```text
homeassistant.components.apple_tv.config_flow: Authentication problem
pyatv.exceptions.PairingError: not authenticated
pyatv.exceptions.PairingError: Error=Authentication, SeqNo=M4
```

The failure occurred during AirPlay or Companion protocol pairing rather than basic discovery.

## Diagnostics

### Confirm Home Assistant host networking

```bash
docker inspect homeassistant --format='{{.HostConfig.NetworkMode}}'
```

Expected result:

```text
host
```

### Review Apple TV pairing errors

```bash
docker logs homeassistant --tail=200 \
  | grep -i -E 'apple|pyatv|auth|mrp|companion|airplay'
```

### Locate the bundled `atvremote` utility

```bash
docker exec homeassistant sh -c \
  'command -v atvremote || ls -l /usr/local/bin/atv*'
```

The Home Assistant image included:

```text
/usr/local/bin/atvremote
```

### Python 3.14 CLI workaround

The bundled `atvremote scan` command failed because no asyncio event loop existed in the main thread. The working diagnostic invocation was:

```bash
docker exec -it homeassistant python3 -c '
import asyncio
from pyatv.scripts.atvremote import main

asyncio.set_event_loop(asyncio.new_event_loop())
main()
' scan
```

The scan confirmed that both Apple TVs advertised:

- Companion
- AirPlay
- RAOP

Companion and AirPlay required pairing, while discovery and network reachability were healthy.

## Pairing Resolution

A direct Companion pairing test succeeded from inside the Home Assistant container. That proved:

- Home Assistant could reach the Apple TV
- PIN presentation worked
- Companion authentication worked
- Docker networking, Pi-hole, and UniFi were not the root cause

After clearing the temporary pairing and retrying the normal Home Assistant integration flow, both Apple TVs paired successfully.

Do not record or commit generated Apple TV pairing credentials. Treat them as secrets. If credentials are exposed, remove the associated remote pairing from the Apple TV and pair again.

## Apple TV Access Settings

During troubleshooting, AirPlay access was temporarily broadened to allow pairing.

After successful pairing, the access policy was tightened and validated with these settings:

- AirPlay: enabled
- Allow Access: anyone on the same network
- Require Password: disabled

Home Assistant retained control after this change.

## Validation

Verified from Home Assistant and the Companion App:

- Play command works
- Pause command works
- Media state updates correctly
- Bedroom Apple TV remains controllable
- Game Room Apple TV remains controllable

## Architecture Decision

Keep the native Home Assistant Apple TV integration for media state and remote-control actions.

Potential future uses:

- Pause playback when the doorbell rings
- Media-aware lighting scenes
- Room occupancy hints based on active playback
- Goodnight and away-mode media shutdown

## Troubleshooting Notes

If an Apple TV disappears from the discovered list after a failed setup attempt:

1. Restart the Apple TV.
2. Wait for it to return to the Home screen.
3. Refresh **Settings > Devices & services** in Home Assistant.

If pairing fails again:

1. Confirm AirPlay is enabled.
2. Temporarily allow access to everyone or anyone on the same network.
3. Confirm no password is required.
4. Review Home Assistant logs for `pyatv` authentication errors.
5. Use the scan command above to confirm advertised protocols.
6. Remove stale remote pairings from the Apple TV before retrying.

## Security Notes

- Keep Apple TV access restricted to the local network after pairing.
- Never commit pairing credentials or PINs.
- Do not expose Apple TV control protocols publicly.
- Home Assistant should remain LAN- or VPN-accessible rather than directly exposed for remote-control use.
