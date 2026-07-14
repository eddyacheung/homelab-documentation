# Home Assistant and Eufy Camera Integration

> Last updated: 2026-07-13

## Purpose

Document the Home Assistant camera integration built for Eufy cameras, the Apple Home export test, and the resulting architecture decision.

## Environment

- Home Assistant Container on the UGREEN DXP4800 Plus
- Docker host networking for Home Assistant
- `eufy-security-ws` container
- `go2rtc` container
- Eufy Security custom integration
- WebRTC Camera integration
- Homebridge retained for Apple Home camera export

## Camera Inventory

- Front Door Doorbell
- Backyard Camera
- Living Room Camera
- Bedroom Camera

The indoor cameras are Eufy Indoor Cam E30 models. They are normally placed in Privacy Mode while the home is occupied.

## Completed Work

### Home Assistant camera pipeline

- Deployed and validated `eufy-security-ws`.
- Deployed and validated `go2rtc`.
- Added the Eufy Security integration to Home Assistant.
- Added the WebRTC Camera integration.
- Confirmed the Backyard camera entity streams successfully in Home Assistant.
- Confirmed the remaining camera entities exist.
- Built a camera dashboard using `custom:webrtc-camera` cards.
- Corrected the dashboard entity reference to `camera.backyard` after a camera-not-found error.

### Dashboard example

```yaml
cards:
  - type: heading
    heading: Security
    heading_style: title
    icon: mdi:cctv

  - type: custom:webrtc-camera
    entity: camera.doorbell

  - type: custom:webrtc-camera
    entity: camera.backyard

  - type: custom:webrtc-camera
    entity: camera.living_room

  - type: custom:webrtc-camera
    entity: camera.bedroom
```

Expected behavior:

- Backyard camera provides a live stream.
- Doorbell may show the latest event snapshot while idle because it conserves battery.
- Indoor camera streams are unavailable while Privacy Mode is enabled.

## HomeKit Bridge Test

Home Assistant created one main bridge and separate accessory-mode entries for each camera:

- `HASS Bridge:21064`
- `Backyard Camera:21065`
- `Bedroom Camera:21066`
- `Living Room Camera:21067`
- `Front Door Doorbell:21068`

Home Assistant uses accessory mode for cameras rather than placing them behind the main bridge.

### Pairing recovery procedure

The HomeKit setup QR codes were not visible initially. The reliable recovery procedure was:

1. Open **Settings > Devices & services > HomeKit Bridge**.
2. Disable the individual unpaired camera accessory.
3. Wait approximately ten seconds.
4. Re-enable the accessory.
5. Open Home Assistant notifications.
6. Scan the newly generated QR code in Apple Home.

This procedure successfully regenerated pairing notifications and allowed the camera accessories to be added.

### Docker validation

Home Assistant is correctly using host networking:

```bash
docker inspect homeassistant --format '{{.HostConfig.NetworkMode}}'
```

Expected result:

```text
host
```

HomeKit setup codes can be observed at container startup or after an accessory is re-enabled:

```bash
docker logs homeassistant 2>&1 | grep -i homekit | tail -100
```

Home Assistant Container does not include the Home Assistant OS `ha` CLI. Commands such as the following are not valid in this deployment:

```bash
docker exec homeassistant ha core check
```

## Performance Findings

### Homebridge

- Apple Home live stream appeared in approximately two seconds.
- Streaming was consistently faster and more reliable during testing.

### Home Assistant HomeKit Bridge

- Apple Home sometimes remained on **Grabbing a live stream...**.
- Startup was slower than the Homebridge Eufy plugin.
- The migration did not improve the day-to-day camera experience.

## Architecture Decision

Homebridge remains the preferred Apple Home bridge for Eufy cameras.

Home Assistant remains installed and integrated with the cameras for:

- WebRTC dashboards
- Camera and detection entities
- Automations
- Presence-aware security logic
- Future notification and lighting workflows

Preferred architecture:

```text
Eufy cameras
├── Homebridge Eufy plugin -> Apple Home camera streaming
└── eufy-security-ws -> Home Assistant
    ├── WebRTC dashboard
    ├── motion and person entities
    └── automations and presence logic
```

Reducing component count is not worth a measurable regression in camera responsiveness.

## Privacy Mode Limitation

Eufy Indoor Cam E30 Privacy Mode physically parks or blocks the camera and disables the video pipeline.

Consequences:

- Apple Home cannot wake the camera for live viewing.
- Homebridge and Home Assistant cannot refresh the thumbnail.
- The Eufy app must currently be used to disable Privacy Mode before streaming resumes.

The preferred future workflow is to avoid Privacy Mode for routine Home/Away behavior and instead use security modes:

### Home mode

- Camera remains online.
- Recording disabled.
- Motion notifications disabled.
- Alarm disabled.
- Apple Home live view remains available for checking the dogs.

### Away mode

- Recording enabled.
- Motion and person detection enabled.
- Notifications enabled.

Home Assistant should become the source of truth for occupancy and switch the appropriate Eufy security behavior automatically.

## Rollback and Cleanup

If a Home Assistant camera accessory was paired with Apple Home during testing:

1. Remove the standalone camera accessory from Apple Home.
2. Delete or disable only the camera accessory-mode entries in HomeKit Bridge.
3. Keep the main `HASS Bridge` entry if it will be used for non-camera entities.
4. Reinstall or enable the Homebridge Eufy plugin.
5. Restart Homebridge and verify the camera stream returns to the approximately two-second baseline.

Do not delete the Eufy Security, WebRTC Camera, `go2rtc`, or `eufy-security-ws` components. They remain useful to Home Assistant independently of Apple Home camera export.

## Future Work

See the **Home Presence and Security Automation** project in `DASHBOARD.md`.
