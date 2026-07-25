# Home Assistant Command Center Dashboard

## Overview

The Home Assistant **Command Center** is the production Overview dashboard for the home. It is designed as a polished, operations-focused landing page rather than a collection of shortcuts.

The completed dashboard consolidates the information that matters most at a glance:

- Home climate and occupancy
- Front and backyard camera views
- Tesla vehicle status
- UGREEN NAS and Docker health
- UniFi gateway and access-point health

The final design intentionally keeps only two Home Assistant dashboards in regular use:

- Command Center
- Voyager

Separate Media, Homelab, Network, Security, and Map dashboards were rejected because they either duplicated information or did not justify permanent sidebar space.

## Production files

- Home Assistant dashboard definition: `/volume1/docker/homeassistant/config/dashboards/command-center.yaml`
- Version-controlled dashboard copy: `home-assistant/dashboards/01-overview.yaml`
- Registered dashboard key: `premium-command-center`
- Dashboard path: `/premium-command-center/overview`

Home Assistant remains in storage mode with the Command Center registered as a YAML dashboard in `configuration.yaml`.

## Final layout

### Hero banner

The hero provides compact whole-home context:

- Greeting
- Home occupancy
- Weather temperature
- Tesla battery percentage
- Running versus total Docker containers
- Internet online or offline status
- Current time and date
- Current weather icon

The final greeting uses a small, muted daypart label with the user name as the visual anchor.

### Home

The Home section contains:

- Honeywell T6 thermostat card
- Current indoor temperature
- HVAC operating state
- Weather summary
- Presence summary

This section was retained largely unchanged because it already had a strong visual hierarchy and useful controls.

### Security

The Security section contains only the two useful live camera views:

- Front Door
- Backyard

Camera taps open entity details instead of navigating to a separate Security dashboard.

### Voyager

The compact Tesla card includes:

- Large Model Y render
- Battery percentage
- Rated range
- Cabin temperature
- Charging state
- Lock state
- Sentry state
- Climate state
- Link to the full Voyager dashboard

Location, odometer, outside temperature, and plugged-in status were removed from the compact card because they duplicated information elsewhere or did not justify permanent space.

The final image sizing uses containment and a small left shift so the complete vehicle remains visible without clipping.

### System Health

The System Health card represents the homelab operations summary:

- CPU utilization
- Memory utilization
- Volume 2 free storage
- Running versus total containers
- Home Assistant state
- Portainer state
- Plex state
- Pi-hole state

The storage metric uses the real UGREEN media volume rather than the NVMe Docker volume.

Current storage entities:

```text
sensor.network_closet_system_monitor_disk_free_ugreen_volume2
sensor.network_closet_system_monitor_disk_use_ugreen_volume2
sensor.network_closet_system_monitor_disk_usage_ugreen_volume2
```

At completion, Volume 2 reported approximately:

- 5,035.9 GiB free
- 15,355.7 GiB used
- 75.3 percent used

The dashboard converts the free-space value to approximately 4.9 TiB for display.

Docker Images was removed because image count is an implementation detail and does not provide useful daily operational context.

### Network

The Network card contains:

- Internet state
- WAN latency
- Total devices
- Wi-Fi clients
- UCG Max state, CPU, memory, and temperature
- U7 Pro state, CPU, and memory
- Firmware state

The earlier three-button summary row was replaced with a compact list layout to eliminate the empty gap after Devices. Gateway and access-point sections are left aligned and use consistent spacing.

System Health and Network use the same desktop height so their bottom borders align.

## Integrations and data sources

### Home Assistant and environment

- Home Assistant Container
- Mushroom Cards
- Button Card
- Card Mod
- Layout Card or Grid Layout support
- Weather integration
- Companion App presence entities

### Cameras

- Eufy entities exposed through `eufy-security-ws`
- go2rtc and WebRTC camera support where applicable

### Tesla

- TeslaMate MQTT telemetry
- Dedicated Voyager dashboard for detailed vehicle information

### Homelab

- Monitor Docker for container counts and service switches
- System Monitor for Volume 2 storage metrics

### Network

- UniFi Network integration

## System Monitor storage configuration

Home Assistant runs on Volume 1, the NVMe Docker volume. The media array is Volume 2.

The Home Assistant container therefore includes a read-only bind mount for Volume 2:

```yaml
volumes:
  - /volume1/docker/homeassistant/config:/config
  - /volume2:/ugreen-volume2:ro
```

Only the following System Monitor entities were enabled for the media volume:

- Disk free `/ugreen-volume2`
- Disk use `/ugreen-volume2`
- Disk usage `/ugreen-volume2`

Docker overlay filesystem entities were intentionally left disabled.

## Primary entity set

```text
person.eddy_cheung
weather.forecast_home
climate.living_room_thermostat_t6_pro_thermostat

sensor.tesla_battery_level
sensor.tesla_rated_range
sensor.tesla_inside_temperature
sensor.tesla_model_y_tesla_charging_state
binary_sensor.tesla_locked
binary_sensor.tesla_sentry_mode
binary_sensor.tesla_climate

sensor.ugreen_docker_cpu
sensor.ugreen_docker_memory_percent
sensor.ugreen_docker_containers_running
sensor.ugreen_docker_containers_total
sensor.network_closet_system_monitor_disk_free_ugreen_volume2
sensor.network_closet_system_monitor_disk_use_ugreen_volume2
sensor.network_closet_system_monitor_disk_usage_ugreen_volume2

switch.ugreen_docker_homeassistant
switch.ugreen_docker_portainer
switch.ugreen_docker_plex
switch.ugreen_docker_pihole

sensor.ucg_max_cpu_utilization
sensor.ucg_max_memory_utilization
sensor.ucg_max_cpu_temperature
sensor.ucg_max_clients
sensor.ucg_max_cloudflare_wan_latency
sensor.ucg_max_state

sensor.u7_pro_cpu_utilization
sensor.u7_pro_memory_utilization
sensor.u7_pro_clients
sensor.u7_pro_state
```

## Design decisions

### Keep the Overview focused

The dashboard answers five questions:

1. Is the home comfortable and occupied?
2. Is anything happening at the perimeter?
3. What is the Tesla doing?
4. Is the homelab healthy?
5. Is the network healthy?

Anything that did not support one of those questions was removed.

### Prefer operational data over implementation details

Examples:

- Storage free replaced Docker image count.
- Internet state replaced a duplicate Wi-Fi client hero pill.
- Charging state replaced a redundant plugged-in indicator.
- Camera details replaced navigation to a separate Security dashboard.

### Avoid duplicate dashboards

The Home, Map, Media, Homelab, Network, and Security dashboard concepts were reviewed and rejected or removed when the Command Center already surfaced their useful daily information.

### Use live values, not hardcoded estimates

The storage tile initially showed no data because the NAS media filesystem was not exposed to Home Assistant. The final implementation mounts Volume 2 read-only and uses real System Monitor entities. The dashboard does not hardcode a nominal 5 TB value.

### Treat image composition carefully

The Tesla render went through several iterations:

- Oversized scaling caused clipping.
- Missing CSS caused default entity icons to render at enormous sizes.
- Excessive scaling made the car dominate the card.
- The accepted version uses `object-fit: contain`, moderate scaling, and a small left shift.

## Rejected experiments and lessons

- Separate Media card containing only service shortcuts
- Separate Homelab or Network dashboard for information already visible on Overview
- Three equal Network buttons that left an empty fourth-column gap
- Docker Images as a primary health metric
- Dense Tesla telemetry containing location, odometer, outside temperature, and duplicate plugged-in state
- Large default Tesla icons caused by lost custom styling
- Aggressive Tesla image scaling that clipped the vehicle
- Storage auto-discovery based on guessed entity IDs
- Monitoring Volume 1 when the actual media array is Volume 2
- Fixed bottom-card heights that were too short and clipped System Health content

## Validation

The completed dashboard was visually validated at desktop width.

Confirmed:

- Hero content is aligned and legible.
- Home, Security, and Voyager have balanced visual weight.
- The Tesla render is fully visible.
- Tesla telemetry and state chips remain readable.
- Volume 2 storage reports approximately 4.9 TiB free.
- System Health and Network bottom borders align.
- CPU and memory values update normally.
- Docker service indicators report Running.
- Internet, latency, client, gateway, access-point, and firmware values update.
- No separate Media section remains.

## Backup and rollback

Before replacing the live dashboard:

```bash
cp /volume1/docker/homeassistant/config/dashboards/command-center.yaml \
  /volume1/docker/homeassistant/config/dashboards/command-center.yaml.backup-$(date +%Y%m%d-%H%M%S)
```

Validate Home Assistant configuration:

```bash
docker exec homeassistant python -m homeassistant \
  --script check_config \
  --config /config
```

Restart when necessary:

```bash
docker restart homeassistant
```

Then hard-refresh the browser with `Ctrl+Shift+R`.

To restore:

```bash
cp /volume1/docker/homeassistant/config/dashboards/command-center.yaml.backup-YYYYMMDD-HHMMSS \
  /volume1/docker/homeassistant/config/dashboards/command-center.yaml

docker restart homeassistant
```

## Current status

**Status: Complete**

The current Command Center Overview is the accepted production baseline. Future work should focus on conditional alerts and better host-level NAS telemetry rather than additional layout iteration.

## Optional future enhancements

- Replace Docker-derived CPU and memory with authoritative UGREEN host metrics if a suitable integration is added.
- Change the System Health badge to identify an offline service.
- Turn storage amber or red at defined free-space thresholds.
- Change the Network badge for high WAN latency or disconnected infrastructure.
- Make the compact Tesla card state-aware for charging or driving.
- Add warning-only security states for camera unavailability or motion events.
- Validate responsive behavior on tablet and phone widths.
