# Home Assistant Command Center Completion

**Date:** 2026-07-25  
**Status:** Complete

## Summary

Completed the production Home Assistant Command Center Overview dashboard after several design and validation sessions.

The final dashboard now provides a single polished landing page for:

- Home climate and presence
- Front and backyard cameras
- Tesla vehicle status
- UGREEN NAS and Docker health
- UniFi network health

The design intentionally avoids separate Media, Homelab, Network, Security, Map, and duplicate Home dashboards.

## Completed work

### Dashboard structure

- Retained only Command Center and Voyager as primary dashboards.
- Finalized a three-column top row for Home, Security, and Voyager.
- Finalized an equal-height bottom row for System Health and Network.
- Removed the Media section because service shortcuts did not provide enough daily value.

### Hero

- Added compact pills for Home, weather, Tesla battery, containers, and Internet state.
- Removed duplicate Wi-Fi client information.
- Refined the greeting so the daypart is muted and the user name is emphasized.

### Security

- Retained Front Door and Backyard camera views.
- Changed camera taps to entity details instead of a separate Security dashboard.

### Tesla compact card

- Reduced the card to battery, range, cabin temperature, charging, lock, Sentry, and climate.
- Removed location, odometer, outside temperature, and duplicate plugged-in state.
- Corrected a CSS regression that caused oversized default icons.
- Corrected vehicle clipping by reducing image scaling, using containment, and shifting the render slightly left.
- Retained the Open Voyager link to the full vehicle dashboard.

### System Health

- Removed Docker Images.
- Added live media-array storage reporting.
- Mounted UGREEN Volume 2 read-only inside the Home Assistant container as `/ugreen-volume2`.
- Enabled only the relevant System Monitor disk free, disk use, and disk usage entities.
- Confirmed approximately 4.9 TiB free and 75.3 percent used.
- Retained CPU, memory, running/total containers, and four critical service indicators.

### Network

- Replaced the uneven three-button summary with a compact two-column information layout.
- Retained Internet, latency, total devices, Wi-Fi clients, UCG Max health, U7 Pro health, and firmware state.
- Removed duplicate client counts from infrastructure detail.
- Matched the desktop height of System Health so both card bottoms align.

## Production storage entities

```text
sensor.network_closet_system_monitor_disk_free_ugreen_volume2
sensor.network_closet_system_monitor_disk_use_ugreen_volume2
sensor.network_closet_system_monitor_disk_usage_ugreen_volume2
```

## Validation

Validated visually in Home Assistant at desktop width:

- Tesla vehicle is fully visible and no longer clipped.
- Tesla telemetry and status chips display normally.
- Storage reports approximately 4.9 TiB free.
- CPU and memory values update.
- All 28 monitored containers report running.
- Home Assistant, Portainer, Plex, and Pi-hole report Running.
- Network gateway, access point, latency, clients, and firmware display normally.
- System Health and Network bottom borders align.
- The overall dashboard is accepted as the production baseline.

## Files

- Documentation: `services/home-assistant-command-center-dashboard.md`
- Version-controlled YAML: `home-assistant/dashboards/01-overview.yaml`
- Live file: `/volume1/docker/homeassistant/config/dashboards/command-center.yaml`

## Future work

Future changes should prioritize behavior instead of additional layout churn:

- Host-authoritative NAS CPU and memory metrics
- Low-storage warning states
- Offline-container warning states
- High-latency or disconnected-network states
- State-aware Tesla charging and driving presentation
- Responsive validation on tablet and phone
