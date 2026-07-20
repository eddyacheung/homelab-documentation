# Home Assistant Tesla Dashboard

## Overview

Home Assistant includes a dedicated read-only Tesla Model Y dashboard named **Voyager**. It consumes TeslaMate MQTT telemetry and is designed as a vehicle operations dashboard rather than a replacement for the Tesla mobile app.

The Tesla app remains the control surface. Voyager focuses on current health, charging, climate, openings, tire pressure, and historical trends. It does not expose lock, climate, charging, trunk, frunk, or other Tesla command actions.

## Current architecture

- Home Assistant runs as a Docker container on the UGREEN NAS.
- Home Assistant uses host networking.
- Dashboard YAML: `/volume1/docker/homeassistant/config/dashboards/tesla.yaml`
- Dashboard path: `/tesla-car/model-y`
- Telemetry source: TeslaMate MQTT entities
- Current production hero image: `/volume1/docker/homeassistant/config/www/tesla/model-y-juniper-hero-v5.6.png`
- Home Assistant image reference: `/local/tesla/model-y-juniper-hero-v5.6.png`

## Frontend dependencies

The dashboard currently uses:

- Mushroom Cards
- Card Mod
- Auto Entities where required by older experiments or other dashboards
- Home Assistant history graph cards on the Insights page

After changing frontend resources, restart Home Assistant when required and hard-refresh the browser with `Ctrl+Shift+R`.

## Current dashboard structure

Voyager now has two views.

### Overview

The Overview page answers:

- Where is the car?
- What state is it in?
- Is it locked and healthy?
- How much battery and rated range remain?
- Is it connected or charging?
- Is anything open?
- Are climate and tire pressures normal?

#### Hero

The full-width hero is a `picture-elements` card with:

- Left-side status stack:
  - Voyager
  - Current vehicle state
  - Location
  - Battery percentage and rated range
- Right-side three-quarter Model Y render
- Full-width centered status-chip row:
  - Lock
  - Battery
  - Rated range
  - Location
  - Sentry
  - Healthy or Attention

The current chip card uses `grid_options: columns: full` so the health chip remains on the same row at desktop width.

#### Current-status columns

The page uses three normal Home Assistant Sections columns rather than a nested fixed grid.

**Vehicle**

- Vehicle state
- Location
- Odometer
- Sentry

**Openings**

- Doors
- Windows
- Frunk
- Trunk

**Battery & Range**

- Battery percentage
- Rated range
- Charge limit
- Energy added

**Charging**

- Cable status
- Charge state
- Charging power
- Time to full

**Climate & Comfort**

- Cabin temperature
- Outside temperature
- Climate state
- Preconditioning state

**Tire pressure**

- Front left
- Front right
- Rear left
- Rear right

The duplicate Lock tile was removed from the Vehicle section because lock status is already visible in the hero chip row. This leaves each top section with four cards and improves column alignment.

### Insights

The Insights page provides historical information that is less accessible in the Tesla app:

- Seven-day battery history
- Seven-day rated-range history
- Seven-day cabin and outside temperature history
- Battery context
- Vehicle context
- Climate context
- Seven-day tire-pressure comparison

The page intentionally uses equal graph sizes and matching context-card structures to maintain alignment.

## Primary entity set

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
binary_sensor.tesla_healthy
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

## State presentation

The dashboard maps TeslaMate state values into friendlier display text.

Examples:

- `asleep`, `sleeping`, or the observed parked `offline` state display as `Sleeping`
- `online` or `idle` display as `Parked`
- `charging` displays as `Charging`
- Unknown values remain visible rather than being silently hidden

This mapping is presentation-only. It does not change the underlying TeslaMate entity.

## Dynamic health chip

The final hero chip is compact so all six chips fit on one row.

Normal state:

```text
Healthy
```

Problem state:

```text
Attention
```

The chip evaluates lock, doors, windows, frunk, trunk, and TeslaMate health. A future refinement may hide the health chip during normal operation and show only problem-specific warning chips.

## Key layout lessons

### Sections are responsive

Home Assistant Sections views do not behave like a rigid desktop CSS grid. A nested three-column grid produced precise alignment but compressed every card into narrow tiles. The selected design therefore uses three normal Sections columns with identical card counts and structures.

### Use real asset composition instead of CSS scaling

Repeated attempts to resize the original portrait image with `aspect_ratio`, fixed heights, and `object-fit` caused oversized, clipped, or tiny vehicle renders.

The reliable approach was to create a purpose-built wide hero image with:

- A transparent 1600 by 400 canvas
- The complete three-quarter car render cropped from its source margins
- The vehicle positioned toward the right
- Empty space retained on the left for status elements

### Full-width chip cards must be declared at the grid level

CSS attempts to force Mushroom chips onto one row were ineffective because the card itself occupied only part of the section. The durable fix was:

```yaml
grid_options:
  columns: full
```

### Avoid over-consolidating cards

Combining several values into twelve large cards reduced card count but made the dashboard harder to scan. The final design restores one primary metric per tile while retaining the polished hero and aligned section structure.

### Avoid duplicate status unless it improves scanability

Hero chips intentionally repeat a few high-value values such as battery and range. The duplicate Lock tile in the Vehicle section was removed because it did not add enough value to justify the extra row.

## Rejected experiments

- Four-page and three-page dashboard structures
- A standalone Controls page for a dashboard intended to remain read-only
- A nested three-column grid that compressed all cards
- Oversized portrait picture cards
- Invalid or ineffective picture-card aspect-ratio adjustments
- Fixed-height picture-elements cards that clipped the vehicle
- Top-down image used accidentally as the hero
- Wide banners made from the wrong source asset
- Over-consolidated cards that reduced scanability
- CSS-only Mushroom chip nowrap overrides
- Large permanent health cards that competed with the status chips
- Keeping a 24-hour battery graph on Overview when historical data already exists on Insights

## Backup and rollback

Before replacing the dashboard:

```bash
cp /volume1/docker/homeassistant/config/dashboards/tesla.yaml \
  /volume1/docker/homeassistant/config/dashboards/tesla.yaml.backup-$(date +%Y%m%d-%H%M%S)
```

Validate configuration:

```bash
docker exec homeassistant python -m homeassistant \
  --script check_config \
  --config /config
```

Restart when required:

```bash
docker restart homeassistant
```

Then hard-refresh the browser with `Ctrl+Shift+R`.

Confirm the file still contains exactly two views:

```bash
grep -n "^  - title:" \
  /volume1/docker/homeassistant/config/dashboards/tesla.yaml
```

Expected titles:

```text
Overview
Insights
```

## Current status

The current Overview design is accepted as the production baseline.

Validated visually:

- Full vehicle is visible at a useful hero size
- Hero status stack reads naturally
- Six hero chips display in one row at desktop width
- Vehicle, Battery & Range, and Climate & Comfort sections align closely
- Overview does not contain redundant historical graphs
- Insights graphs and context cards remain aligned
- Dashboard remains read-only

## Asset cleanup

Multiple experimental images accumulated while refining the hero. Cleanup is tracked in GitHub issue #5.

Before deleting anything, compare the live asset inventory with every `/local/tesla/` reference in `tesla.yaml`. Keep the current production hero, the original source render if desired, and at least one known-good dashboard rollback file.

## Future work

- Rebuild the hero as a dedicated responsive two-column layout only if the current picture-elements design becomes difficult to maintain
- Replace the permanent Healthy chip with warning chips that appear only for actionable conditions
- Add software-update detection when a reliable entity is available
- Add vampire-drain analysis
- Add charging-efficiency and charging-session summaries
- Add last-drive distance and efficiency context
- Match any future Insights refinements to the Overview typography and spacing
- Validate responsive behavior on tablet and phone widths
