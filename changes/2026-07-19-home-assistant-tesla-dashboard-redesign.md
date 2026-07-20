# Home Assistant Tesla Dashboard Redesign

**Date:** 2026-07-19

## Summary

Redesigned the Home Assistant Voyager Tesla dashboard from a multi-page card collection into a two-view, read-only vehicle operations dashboard.

The work focused on information architecture, responsive alignment, hero composition, historical insights, and reducing duplication without sacrificing scanability.

## Final architecture

### Overview

Current vehicle status and health:

- Full-width picture-elements hero
- Left-side Voyager status stack
- Right-positioned Model Y render
- Full-width status-chip row
- Vehicle and security
- Openings
- Battery & Range
- Charging
- Climate & Comfort
- Tire pressure

### Insights

Historical TeslaMate telemetry:

- Seven-day battery history
- Seven-day rated-range history
- Seven-day cabin and outside temperature history
- Battery, vehicle, and climate context cards
- Seven-day tire-pressure comparison

## Design decisions

- Kept the dashboard read-only; Tesla controls remain in the Tesla app.
- Reduced the dashboard to two pages.
- Removed the standalone Controls page.
- Removed the 24-hour battery graph from Overview because Insights already provides historical data.
- Used one metric per tile after over-consolidated cards proved harder to scan.
- Removed the duplicate Lock tile from Vehicle because lock status is already present in the hero chips.
- Kept hero chips for Lock, Battery, Range, Home, Sentry, and Health.
- Renamed major sections to `Battery & Range` and `Climate & Comfort`.

## Hero evolution

Several hero approaches were tested and rejected:

- Natural-size portrait picture card
- Fixed-height picture-elements card
- Aspect-ratio-only resizing
- Top-down image hero
- Wide banner built from the wrong source image
- Nested two-column hero that made the car too small

The selected approach uses:

- A 1600 by 400 transparent hero asset
- A tightly cropped three-quarter Model Y render positioned on the right
- Picture-elements status cards positioned on the left
- A full-width Mushroom chip row below the hero

The production hero asset is:

```text
/volume1/docker/homeassistant/config/www/tesla/model-y-juniper-hero-v5.6.png
```

## Layout lessons

- Home Assistant Sections views are responsive and should not be treated as fixed CSS grids.
- A nested three-column grid aligned rows but compressed all cards.
- Three normal Sections columns with matching card counts gave the best balance.
- CSS could not force Mushroom chips to use space the parent grid had not allocated.
- `grid_options: columns: full` on the chip card solved the desktop wrapping issue.
- Purpose-built image assets were more reliable than CSS transforms and object-fit experiments.

## Validation

Validated after deployment:

- Dashboard contains exactly two views: Overview and Insights.
- Full vehicle is visible without clipping.
- Hero status elements and car image are balanced.
- Six hero chips appear on one row at desktop width.
- Three Overview columns align closely.
- Insights graphs remain aligned.
- Vehicle, charging, climate, opening, and tire entities populate correctly.
- Dashboard remains read-only.

## Cleanup follow-up

Multiple experimental Tesla images remain under the Home Assistant asset directory. Cleanup is tracked in GitHub issue #5:

- Inventory live `/local/tesla/` references.
- Back up the asset directory.
- Remove only unreferenced hero, top-down, banner, crop, and versioned experiment files.
- Retain the production hero and at least one known-good rollback source.
