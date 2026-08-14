# Home Assistant RATGDO Garage Door Integration

**Date:** 2026-08-13

## Overview

A Gelidus Research RATGDO Alternate Board AC USB-C v2 was integrated with the existing Chamberlain/LiftMaster myQ garage door opener to provide local garage-door status and control through Home Assistant, Apple Home, and Siri.

The existing myQ connection remains available. RATGDO provides the preferred local Home Assistant control path and does not depend on the myQ cloud for normal Home Assistant operation.

## Components

- Gelidus Research RATGDO Alternate Board AC USB-C v2
- ESPHome RATGDO firmware supplied with the board
- Chamberlain/LiftMaster myQ garage door opener using Security+ 2.0
- Home Assistant
- Home Assistant ESPHome integration
- Home Assistant HomeKit Bridge
- UniFi IoT network
- Apple Home / Siri

## Network Configuration

The RATGDO is connected to the dedicated IoT VLAN.

| Setting | Value |
| --- | --- |
| UniFi client name | Garage RATGDO |
| Network | IoT |
| Subnet | `192.168.20.0/24` |
| Reserved IP | `192.168.20.50` |
| Wi-Fi band | 2.4 GHz |

Home Assistant successfully discovered the ESPHome device across the VLAN, confirming the required local communication path is available.

## ESPHome and Home Assistant

After the board joined the IoT Wi-Fi network, Home Assistant automatically discovered it as an ESPHome device.

The device was added through **Settings > Devices & services** and renamed to **Garage Door**.

No additional firmware flashing was required during the completed installation. The supplied ESPHome RATGDO firmware successfully exposed the garage-door entities to Home Assistant.

Useful entities include:

- Door cover and current position/state
- Garage opener light
- Obstruction status
- Motion status
- Motor status
- Learned opening and closing duration

Internal configuration and diagnostic entities such as rolling-code counters and client identifiers should normally be left unchanged.

## Learned Door Timing

After a complete open/close test cycle, RATGDO learned approximately:

| Direction | Duration |
| --- | ---: |
| Opening | 12.5 seconds |
| Closing | 12.4 seconds |

These values were populated automatically after normal operation.

## HomeKit Bridge

The existing Home Assistant HomeKit Bridge was updated rather than creating another bridge.

Bridge entry:

`HASS Bridge:21064`

The bridge uses inclusion filtering. The **Cover** domain was added while retaining the existing Script and Climate selections, and the RATGDO **Door** cover entity was explicitly selected for export.

Only the actual garage-door cover is required for Apple Home. Diagnostic entities, restart controls, rolling-code values, and other internal RATGDO controls are not exported.

HomeKit presents the entity as a native garage-door accessory, including open/closed state and open/close commands.

## Validation

The completed integration was tested end to end.

- RATGDO connected successfully to the IoT VLAN.
- Home Assistant automatically discovered the ESPHome device.
- Home Assistant displayed current garage-door state.
- Garage opener light control worked from Home Assistant.
- Door open command worked from Home Assistant.
- Door close command worked from Home Assistant.
- Door state updated correctly during movement.
- Obstruction status reported OK.
- Opening and closing durations were learned successfully.
- Garage Door appeared in Apple Home through HomeKit Bridge.
- Apple Home successfully opened and closed the garage door.
- Siri successfully accepted open and close commands.
- Apple Home and Siri can report garage-door status.
- Existing myQ connectivity remains available.

## Architecture

```text
Chamberlain/LiftMaster opener
          |
          | Security+ 2.0 local interface
          v
   Gelidus RATGDO
          |
          | Wi-Fi / IoT VLAN
          v
      ESPHome
          |
          v
   Home Assistant
          |
          | HomeKit Bridge
          v
     Apple Home
          |
          v
        Siri
```

## Operational Notes

- RATGDO is the preferred local automation and Apple Home integration path.
- myQ may remain enabled as a separate vendor application/fallback path.
- Keep the RATGDO IP reservation at `192.168.20.50` unless the network addressing plan changes.
- If the device becomes unavailable, first verify that `Garage RATGDO` remains connected to the IoT network and that Home Assistant can reach it across VLAN boundaries.
- Avoid changing ESPHome diagnostic/configuration values unless troubleshooting requires it.
- HomeKit exposure should remain limited to useful user-facing entities.

## Result

The garage door is now locally integrated with Home Assistant and exposed as a native garage-door accessory to Apple Home. Door status and open/close control are available from both the Apple Home app and Siri without relying on myQ for the Home Assistant control path.
