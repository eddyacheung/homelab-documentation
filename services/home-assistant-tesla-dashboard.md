# Home Assistant Tesla Dashboard

## Overview

Home Assistant now includes a dedicated read-only Tesla Model Y dashboard named **Voyager**. The dashboard consumes TeslaMate MQTT telemetry and presents vehicle, battery, charging, climate, security, opening, odometer, location, and tire-pressure information in a three-column desktop layout.

The dashboard is intentionally telemetry-focused. It does not add Tesla command access or require a virtual key.

## Current architecture

- Home Assistant runs as a Docker container on the UGREEN NAS.
- Home Assistant uses host networking.
- The dashboard is stored at `/volume1/docker/homeassistant/config/dashboards/tesla.yaml`.
- The dashboard path is `/tesla-car/model-y`.
- The dashboard uses TeslaMate-derived MQTT entities.
- The hero image is stored at `/volume1/docker/homeassistant/config/www/tesla/model-y-juniper.png` and referenced as `/local/tesla/model-y-juniper.png`.

## Frontend dependencies

The dashboard depends on these HACS frontend components:

- Mushroom Cards
- Card Mod
- Auto Entities
- ApexCharts Card

After installing or upgrading a frontend component, restart Home Assistant when required and perform a browser hard refresh with `Ctrl+F5`.

## Dashboard layout

### Left column: vehicle overview

- Voyager title and Home location subtitle
- Model Y Juniper hero image
- Quick-status chips for battery, range, lock, location, and Sentry mode
- Battery summary with remaining range and progress bar
- Vehicle state, location, rated range, and odometer cards

### Middle column: charging and battery history

- Dynamic charging summary
- Unplugged metrics: battery, rated range, charging power, and odometer
- Plugged-in metrics: charge limit, current, voltage, and time to full
- Twenty-four-hour battery history using ApexCharts

### Right column: vehicle systems

- Cabin and outside temperature
- Climate and preconditioning state
- Lock and Sentry mode
- Doors, windows, frunk, and trunk
- Four tire-pressure cards with color thresholds
- Auto Entities tire-warning section when warning entities are active

## Current entity set

The dashboard currently references these primary entities:

```text
sensor.tesla_state
sensor.tesla_location
sensor.tesla_battery_level
sensor.tesla_rated_range
sensor.tesla_odometer
sensor.tesla_inside_temperature
sensor.tesla_outside_temperature
binary_sensor.tesla_locked
binary_sensor.tesla_sentry_mode
binary_sensor.tesla_climate
binary_sensor.tesla_doors_open
binary_sensor.tesla_trunk
binary_sensor.tesla_model_y_tesla_plugged_in
binary_sensor.tesla_model_y_tesla_preconditioning
binary_sensor.tesla_model_y_tesla_windows_open
binary_sensor.tesla_model_y_tesla_frunk
sensor.tesla_model_y_tesla_charging_state
sensor.tesla_model_y_tesla_charge_limit
sensor.tesla_model_y_tesla_time_to_full_charge
sensor.tesla_model_y_tesla_charger_power
sensor.tesla_model_y_tesla_charge_energy_added
sensor.tesla_model_y_tesla_charger_current
sensor.tesla_model_y_tesla_charger_voltage
sensor.tesla_front_left_tire_pressure
sensor.tesla_front_right_tire_pressure
sensor.tesla_rear_left_tire_pressure
sensor.tesla_rear_right_tire_pressure
```

The confirmed raw vehicle state during this session was:

```text
sensor.tesla_state = offline
```

The dashboard therefore reports `Offline` rather than assuming that the vehicle is sleeping.

## ApexCharts configuration

The stock Home Assistant `history-graph` card was replaced with `custom:apexcharts-card`.

Current design decisions:

- Twenty-four-hour span
- Five-minute update interval
- Ten-minute `last` grouping
- Blue `#4DA3FF` area series
- Smooth curve
- Three-pixel stroke
- Zero-to-one-hundred percent Y-axis
- Current battery percentage in the card header
- Three-hundred-pixel chart height
- Hidden legend and data labels

A known failure mode is an ApexCharts card showing `N/A`, `Loading...`, or an incorrect zero-to-six scale. The working configuration requires numeric Y-axis bounds:

```yaml
yaxis:
  - min: 0
    max: 100
    decimals: 0
```

Do not use `~0` or `~100` for this card.

## Hero image lessons

Using CSS `transform: scale(...)` enlarged the image without enlarging the layout box and caused the lower part of the vehicle to be clipped.

The preferred method is:

- Give the picture card a fixed height.
- Use `object-fit: contain`.
- Adjust image width and horizontal margin rather than CSS transforms.
- Keep `overflow: visible` only when required.

The selected aligned baseline uses a fixed-height hero card and avoids transform-based scaling.

## Layout lessons

Home Assistant Sections views are responsive and do not behave like a rigid desktop CSS grid. Attempts to force exact bottom alignment with large spacers, duplicate cards, and aggressive fixed heights created more visual problems than they solved.

The selected baseline is the last aligned version. It keeps the richer information layout and accepts small responsive differences between column bottoms.

A modest amount of duplicated information is intentional:

- Hero chips provide quick glanceability.
- The battery summary gives a readable overview.
- Charging metrics provide context while troubleshooting charging.
- Battery History provides trend context.

An experimental deduplicated version removed too much information and made the dashboard feel sparse. It was rejected and the aligned baseline was restored.

## Backup and rollback

Before replacing the dashboard YAML:

```bash
cp /volume1/docker/homeassistant/config/dashboards/tesla.yaml \
  /volume1/docker/homeassistant/config/dashboards/tesla-backup-$(date +%Y%m%d-%H%M%S).yaml
```

If a replacement breaks the dashboard, restore the newest known-good backup and hard refresh the browser.

To inspect a YAML parse error around a specific line:

```bash
nl -ba /volume1/docker/homeassistant/config/dashboards/tesla.yaml | sed -n '140,160p'
```

One failed replacement accidentally contained pasted chat transcript text rather than YAML. Signs included lines such as `image(509).png`, prose instructions, and `Ctrl+W`. Always verify that a downloaded file begins with valid dashboard YAML before replacing the live file.

Useful checks:

```bash
head -n 8 /volume1/docker/homeassistant/config/dashboards/tesla.yaml
grep -nE 'Thanks, this screenshot|image\([0-9]+\)\.png|Ctrl\+W' \
  /volume1/docker/homeassistant/config/dashboards/tesla.yaml
```

The grep command should return no output.

## Validation workflow

For normal dashboard-only changes:

1. Back up `tesla.yaml`.
2. Replace or edit the file.
3. Hard refresh the browser with `Ctrl+F5`.
4. Restart Home Assistant only if the YAML dashboard does not reload or a frontend resource requires it.
5. Confirm all three columns load without configuration errors.
6. Confirm ApexCharts displays a numeric battery state and history.
7. Confirm the unplugged and plugged-in conditional grids switch correctly.

## Current status

The dashboard is functional and selected as the Version 1 baseline.

Validated during the session:

- Hero image renders without the earlier checkerboard/transparency workflow.
- Battery percentage and rated range display correctly.
- `mi` is shown in remaining-range text.
- Charging summary and dynamic metrics load.
- ApexCharts displays the battery history in blue.
- Vehicle state reports the real `offline` state.
- Climate, lock, Sentry, openings, odometer, location, and tire pressure load.

## Rejected experiments

- Transform-based hero-image scaling because it clipped the vehicle.
- A custom manually edited transparent top-down PNG because transparency was unreliable.
- Moving Battery History under Vehicle because the charging column became empty.
- Removing most duplicate battery and range information because the dashboard became sparse.
- Energy Summary cards because they repeated existing data.
- Large spacer cards and aggressive bottom-alignment fixes because the Sections layout remained responsive.
- Treating `offline` as `sleeping` because the raw entity did not prove that state.

## Future work

- Build an interactive top-down Juniper view only after obtaining a suitable layered asset set.
- Consider a dedicated Trips page using TeslaMate drive and efficiency data.
- Consider long-term battery-health or degradation reporting when reliable entities or database queries are defined.
- Refine tire-pressure thresholds after confirming preferred normal pressure ranges.
- Validate the plugged-in conditional cards during a real charging session.
- Preserve the current aligned dashboard as the rollback baseline before any Version 2 redesign.
