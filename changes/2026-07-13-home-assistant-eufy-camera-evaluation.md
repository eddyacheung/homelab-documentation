# Home Assistant and Eufy Camera Evaluation

**Date:** 2026-07-13

## Summary

Integrated Eufy cameras with Home Assistant, validated WebRTC dashboard streaming, tested Home Assistant HomeKit camera export, and compared Apple Home performance against the existing Homebridge Eufy plugin.

## Changes Completed

- Validated the `homeassistant`, `eufy-security-ws`, and `go2rtc` containers.
- Confirmed Home Assistant uses Docker host networking.
- Added and validated Eufy Security and WebRTC Camera integrations.
- Confirmed `camera.backyard` streams in Home Assistant.
- Built a multi-camera WebRTC dashboard.
- Created HomeKit Bridge accessory-mode entries for the four Eufy cameras.
- Recovered missing HomeKit pairing notifications by disabling and re-enabling each accessory.
- Paired Home Assistant camera accessories with Apple Home.
- Compared live-stream behavior with Homebridge.

## Validation Results

- Home Assistant WebRTC dashboard: functional.
- HomeKit discovery and pairing: functional after QR-code regeneration.
- Home Assistant Apple Home stream: slower and sometimes remained on **Grabbing a live stream...**.
- Homebridge Apple Home stream: approximately two seconds and more reliable.

## Decision

Retain Homebridge as the Apple Home camera bridge for Eufy devices.

Retain Home Assistant camera integration for dashboards, camera/detection entities, and automations.

## Indoor Camera Finding

The Eufy Indoor Cam E30 Privacy Mode disables live streaming and prevents Apple Home thumbnails from refreshing. A future Home Presence and Security Automation project will investigate keeping the cameras online while disabling recording and notifications at home, then enabling monitoring automatically when away.

## Follow-Up

- Restore or verify the Homebridge Eufy plugin.
- Remove temporary Home Assistant camera accessories from Apple Home.
- Keep the main Home Assistant bridge only if needed for non-camera entities.
- Implement presence-driven Home/Away security behavior.
