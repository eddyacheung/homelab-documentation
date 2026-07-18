# 2026-07-17 - Home Assistant Tesla Dashboard

## Summary

Built and refined a dedicated Home Assistant Tesla Model Y dashboard using TeslaMate MQTT telemetry. The session focused on information layout, charging context, battery history, hero-image rendering, and practical rollback procedures.

## Completed work

- Built a three-column Sections dashboard named **Voyager**.
- Added the Model Y Juniper hero image.
- Added vehicle status chips and a battery summary card.
- Added vehicle state, location, range, and odometer cards.
- Added charging summary and conditional charging metrics.
- Added climate, security, door, window, frunk, trunk, and tire-pressure cards.
- Installed and configured ApexCharts Card through HACS.
- Replaced the stock Battery History graph with a blue ApexCharts area graph.
- Corrected remaining-range display so it includes `mi`.
- Confirmed the raw vehicle-state entity currently reports `offline`.
- Selected the last aligned dashboard as the Version 1 baseline.

## Validation

The selected baseline successfully displayed:

- Battery level: approximately 55 percent during validation
- Rated range: approximately 169 miles during validation
- Location: Home
- Odometer: approximately 11,363 miles during validation
- Lock and Sentry state
- Cabin and outside temperatures
- Door, trunk, window, and frunk states
- Four tire-pressure values
- Twenty-four-hour battery history

## Issues encountered

### YAML indentation errors

Several manual Nano edits produced invalid YAML. The most useful diagnostic was:

```bash
nl -ba /volume1/docker/homeassistant/config/dashboards/tesla.yaml | sed -n '140,160p'
```

### Corrupted replacement file

One downloaded replacement contained chat transcript text instead of YAML. The file included screenshot names and prose such as `Ctrl+W`, which caused Home Assistant parse errors.

The recovery process was:

1. Restore the newest known-good backup.
2. Verify downloaded file size and contents before replacing the live file.
3. Upload as a temporary filename.
4. Inspect the beginning of the file and search for transcript artifacts.
5. Replace the live file only after validation.

### ApexCharts N/A and Loading state

The chart displayed `N/A`, `Loading...`, and a zero-to-six scale when the Y-axis used soft-bound syntax.

The fix was:

```yaml
yaxis:
  - min: 0
    max: 100
    decimals: 0
```

### Hero-image clipping

CSS `transform: scale(...)` clipped the bottom of the vehicle because the layout box did not grow with the transform.

The preferred solution uses a fixed-height picture card, `object-fit: contain`, and direct width/margin adjustments.

## Design decisions

- Battery History remains under Charging.
- Blue was selected instead of ApexCharts orange because it matches the rest of the dashboard.
- The dashboard keeps some repeated battery and range information because it improves glanceability in different contexts.
- Exact bottom alignment is not treated as a hard requirement because Home Assistant Sections is responsive rather than a rigid grid.
- The manual top-down transparent-image workflow was abandoned.
- The aligned dashboard was restored after a deduplicated experiment made the page feel too sparse.

## Rollback

Before future edits:

```bash
cp /volume1/docker/homeassistant/config/dashboards/tesla.yaml \
  /volume1/docker/homeassistant/config/dashboards/tesla-backup-$(date +%Y%m%d-%H%M%S).yaml
```

The current aligned dashboard should be preserved as the Version 1 rollback baseline.

## Follow-up

- Validate the plugged-in conditional grid during a real charging session.
- Consider a Version 2 redesign only after using Version 1 for a while.
- Add a layered top-down Juniper visualization only when suitable assets are available.
- Consider Trips and battery-health pages later.

## Related documentation

- `services/home-assistant-tesla-dashboard.md`
- `services/teslamate.md`
- `DASHBOARD.md`
