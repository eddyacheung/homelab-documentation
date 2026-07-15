# Home Assistant Presence and Eufy Security Automation

> Last updated: 2026-07-14

## Purpose

Use Home Assistant as the source of truth for occupancy and automatically switch the Eufy indoor cameras between Home and Away guard modes.

The design keeps the cameras online while home so Apple Home live viewing remains available, while avoiding routine dependence on Eufy's geofencing.

## Components

- Home Assistant Companion App on iPhone
- Home Assistant `person` entity
- Companion App GPS device tracker
- Home zone with a 100-meter radius
- Eufy Security integration
- Bedroom Eufy Indoor Cam E30
- Living Room Eufy Indoor Cam E30
- Reusable Home Assistant scripts
- Arrival and departure automations

## Companion App Setup

The Companion App initially became trapped reconnecting to an automatically discovered server address.

The working recovery was:

1. Disable Wi-Fi temporarily on the iPhone.
2. Open the Home Assistant Companion App.
3. Manually configure the local Home Assistant URL.
4. Re-enable Wi-Fi after login.

Required iOS permissions:

- Location: Always
- Precise Location: enabled
- Local Network: enabled
- Background App Refresh: enabled
- Notifications: enabled

Verified Companion App sensors included:

- GPS location
- Wi-Fi SSID and BSSID
- Connection type
- Battery level and charging state
- Geocoded location

## Home Zone Correction

The phone initially reported `not_home` even while physically home because the Home zone was centered incorrectly.

The Home zone was corrected to the current residence and configured with a 100-meter radius.

Validation entities:

```text
device_tracker.eddys_iphone
person.eddy_cheung
zone.home
```

After a fresh location update, the device tracker and person entity correctly changed to `home`.

Exact home coordinates are intentionally not recorded in Git.

## Eufy Guard Mode Validation

The Eufy Security integration exposes each indoor camera as an alarm-control entity with guard-mode choices including:

- Away
- Home
- Schedule
- Custom modes
- Geofencing
- Disarmed

Changing the Bedroom camera from Home to Away in Home Assistant immediately updated the Eufy app, confirming bidirectional control.

## Reusable Scripts

Presence detection and Eufy behavior were separated so automations decide **when** to act and scripts define **what** changes.

### Eufy - Set Home Mode

Actions:

- Bedroom Camera: arm home
- Living Room Camera: arm home

### Eufy - Set Away Mode

Actions:

- Bedroom Camera: arm away
- Living Room Camera: arm away

Both scripts were run manually and verified successfully.

## Presence Automations

### Presence - Arrived Home

Trigger:

- Person changes from Away to Home
- No arrival delay

Actions:

- Run `Eufy - Set Home Mode`
- Send a temporary Companion App notification during soak testing

### Presence - Left Home

Trigger:

- Person changes from Home to Away
- State must remain Away for five minutes

Actions:

- Run `Eufy - Set Away Mode`
- Send a temporary Companion App notification during soak testing

The five-minute departure delay reduces false arming caused by brief GPS drift.

## Architecture

```text
iPhone Companion App
        |
        v
Device tracker and Person
        |
        v
Presence automations
        |
        +--> Eufy - Set Home Mode
        |
        +--> Eufy - Set Away Mode
                  |
                  v
       Bedroom and Living Room cameras
```

## Validation

Completed checks:

- Companion App communicates with Home Assistant
- GPS and Wi-Fi sensors report correctly
- Device tracker reports Home inside the corrected zone
- Person entity follows the iPhone tracker
- Arrival and departure automation actions run successfully
- Home and Away scripts change Eufy guard modes
- Eufy app reflects changes initiated by Home Assistant

## Current Operating Model

### Home

- Indoor cameras remain online
- Eufy Home guard mode is selected
- Apple Home live viewing remains available
- Recording and notification behavior is governed by the Eufy Home-mode configuration

### Away

- Eufy Away guard mode is selected after a five-minute confirmed departure
- Recording, detection, and notifications are governed by the Eufy Away-mode configuration

## Rollback

If automatic mode switching becomes unreliable:

1. Disable `Presence - Arrived Home` and `Presence - Left Home`.
2. Continue using the Eufy app for manual guard-mode changes.
3. Leave the reusable scripts in place for manual testing.
4. Review the person and device-tracker histories before re-enabling automations.

## Follow-Up

- Soak test natural departures and arrivals for several days.
- Remove temporary notifications after reliable operation is confirmed.
- Verify the exact recording and notification settings assigned to Eufy Home and Away modes.
- Add a manual override or guest-mode helper before expanding the workflow.
- Consider UniFi presence only if Companion App tracking proves unreliable.
- Keep Homebridge as the Apple Home camera bridge because it remains faster for live streams.
