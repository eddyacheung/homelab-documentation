# Watchtower Update Policy and Notifications

Date: 2026-07-23

## Summary

Completed the Watchtower label-based update workflow and Home Assistant notification integration on the UGREEN NAS.

## Changes

- Retained daily Watchtower scans at 12:00 PM Central.
- Confirmed label-based selection is enabled.
- Finalized automatic-update versus monitor-only behavior.
- Kept qBittorrent and Gluetun in monitor-only mode because they share a network namespace and should be updated together.
- Disabled rolling restarts for compatibility with the qBittorrent/Gluetun architecture.
- Added a custom notification template with manual update commands and a Portainer alternative.
- Moved the Home Assistant webhook URL into an untracked `.env` variable.
- Corrected the webhook host from `127.0.0.1` to the NAS LAN address because localhost inside the Watchtower container refers to Watchtower itself.

## qBittorrent and Gluetun validation

The following state was verified:

- `gluetun` healthy
- `qbittorrent` running through Gluetun's network namespace
- matching public VPN IP from both containers
- no WAN IP leak observed
- Watchtower enable and monitor-only labels present on both containers

Verified monitor-only label output:

```text
enable=true monitor-only=true
enable=true monitor-only=true
```

Verified VPN egress IP at completion:

```text
87.249.138.224
```

## Manual update command

For the qBittorrent Compose project:

```bash
cd /volume1/docker/portainer/compose/47
docker compose -p qbittorrent pull
docker compose -p qbittorrent up -d
```

The stack can also be updated through Portainer by opening the matching stack and selecting **Update the stack** with image re-pull enabled.

## Final Watchtower validation

Healthy startup logs showed:

```text
Watchtower 1.7.1
Using notifications: generic
Only checking containers using enable label
Scheduling first run: 2026-07-23 12:00:00 -0500 CDT
```

The previous Shoutrrr connection-refused error no longer appeared after changing the webhook destination to the NAS LAN address.

## Result

The Watchtower project is complete. Low-risk services can update automatically, protected services can notify only, and Home Assistant notifications include the manual commands needed to perform controlled updates.
