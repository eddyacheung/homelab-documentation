# Radarr Downsizer

## Purpose

`radarr_downsizer_v8.py` is a custom automation that reclaims storage by replacing oversized 2160p movie files with smaller, space-efficient 2160p encodes while preserving conservative quality and safety rules.

The production script runs on the UGREEN NAS at:

```text
/volume1/docker/radarr-downsizer/radarr_downsizer_v8.py
```

The current production version is **v8.2**.

## Current policy

The unattended job uses these thresholds:

- Existing movie must be at least **25 GiB**.
- Replacement must save at least **30%**.
- Torrent must have at least **2 seeders**.
- Candidate must remain a supported **2160p** quality.
- Preferred efficient codecs include x265/H.265/HEVC.
- Runtime-aware size ceilings are enforced for WEBRip-2160p, WEBDL-2160p, and Bluray-2160p.
- Radarr-rejected releases remain blocked except for the narrowly allowed `Existing file meets cutoff` condition.
- Edition/cut changes are blocked by default.

Edition protection detects common markers such as Extended, Theatrical, Director's Cut, Unrated/Uncut, Final Cut, Special Edition, Ultimate Cut, Open Matte, IMAX, Anniversary, and Restored/Restoration. `--allow-edition-change` exists for deliberate manual overrides but is not used by the scheduled job.

## Autonomous workflow

Each v8.2 invocation performs at most one state transition:

1. Inspect the Radarr queue.
2. If a completed downsizer download is stuck at `importPending` only because Radarr says it is not an upgrade, validate the manual-import candidate and finish the import through Radarr in `copy` mode.
3. If Radarr has any active queue item, wait and do not start another downsizer download.
4. If the queue is clear and a previous downsizer job is in flight, verify that the replacement is now present and smaller than the original.
5. If there is no active/in-flight job, scan for the next safe replacement and grab exactly one.
6. If nothing safe is available, remain idle.

The script never directly deletes the existing library movie. Radarr owns the import/replacement operation.

## Proven behavior

The workflow was tested end to end with both normal upgrades and replacements that Radarr would not normally import as an upgrade.

Examples during validation included:

- **Shaun of the Dead**: approximately 50.6 GiB to 13.3 GiB.
- **Step Brothers**: approximately 48.2 GiB Remux-2160p to 12.4 GiB Bluray-2160p; required the safe manual-import finisher.
- **Kingdom of the Planet of the Apes**: approximately 47.5 GiB to 17 GiB through the normal Radarr import path.
- **Casino Royale**: approximately 42.8 GiB to 18.8 GiB.
- **Jumanji: Welcome to the Jungle**: 39.60 GiB to 15.95 GiB, reclaiming 23.65 GiB.
- **Dawn of the Planet of the Apes**: 37.96 GiB to 15.36 GiB, reclaiming 22.60 GiB.

A full-library dry run found **35 safe replacements across 55 oversized movies**, with approximately **502.9 GiB** of estimated reclaimable storage. Four movies had candidates blocked by the edition/cut guard.

## Persistent state and logs

The service maintains:

```text
/volume1/docker/radarr-downsizer/state.json
/volume1/docker/radarr-downsizer/radarr-downsizer.log
/volume1/docker/radarr-downsizer/last-report.json
/volume1/docker/radarr-downsizer/cron.log
```

`state.json` tracks cumulative replacement count and reclaimed bytes. `last-report.json` is a machine-readable representation of the most recent state/action.

## Discord notifications

Notifications are delivered to the Discord channel:

```text
#automation-alerts
```

A dedicated Discord webhook named **Radarr Downsizer** is used. The webhook URL is stored outside Git and must never be committed:

```text
/volume1/docker/radarr-downsizer/discord_webhook
```

Recommended permissions:

```bash
chmod 600 /volume1/docker/radarr-downsizer/discord_webhook
```

Discord is intentionally quiet for normal states. Notifications are sent only for:

- `replaced`
- `attention`
- `error`

Successful replacement embeds include the movie title, before/after size, reclaimed GiB, quality change, cumulative replacement count, and cumulative reclaimed space.

## Scheduled execution

The wrapper script is:

```text
/volume1/docker/radarr-downsizer/run.sh
```

It exports the Radarr API key from the Recyclarr configuration and executes v8.2 with the production thresholds:

```bash
#!/bin/bash

export RADARR_API_KEY="$(awk '/api_key:/ {print $2; exit}' /volume1/docker/recyclarr/config/configs/uhd-bluray-web.yml)"

exec /usr/bin/python3 /volume1/docker/radarr-downsizer/radarr_downsizer_v8.py \
  --existing-min-gib 25 \
  --minimum-savings-percent 30 \
  --min-seeders 2 \
  --apply
```

Root cron runs the wrapper every 30 minutes:

```cron
*/30 * * * * /volume1/docker/radarr-downsizer/run.sh >> /volume1/docker/radarr-downsizer/cron.log 2>&1
```

Because v8.2 checks Radarr state before acting, this cadence does not allow multiple downsizer replacements to pile up concurrently.

## Manual commands

Check the installed version:

```bash
python3 /volume1/docker/radarr-downsizer/radarr_downsizer_v8.py --version
```

Dry run:

```bash
RADARR_API_KEY="$(awk '/api_key:/ {print $2; exit}' /volume1/docker/recyclarr/config/configs/uhd-bluray-web.yml)" \
python3 /volume1/docker/radarr-downsizer/radarr_downsizer_v8.py \
  --existing-min-gib 25 \
  --minimum-savings-percent 30 \
  --min-seeders 2
```

Live one-step orchestration:

```bash
RADARR_API_KEY="$(awk '/api_key:/ {print $2; exit}' /volume1/docker/recyclarr/config/configs/uhd-bluray-web.yml)" \
python3 /volume1/docker/radarr-downsizer/radarr_downsizer_v8.py \
  --existing-min-gib 25 \
  --minimum-savings-percent 30 \
  --min-seeders 2 \
  --apply
```

## Recycle-bin policy

Radarr's application recycle bin is disabled so storage from successfully replaced files is reclaimed immediately instead of being held for seven days.

Verified API state:

```json
{
  "recycleBin": "",
  "recycleBinCleanupDays": 7
}
```

The cleanup-days value is inert while the recycle-bin path is empty.

UGREEN's `#recycle` mechanism does not intercept normal local filesystem deletes from Docker/Radarr, which was verified with a test file. It remains useful for deletions performed through UGREEN/SMB but is not part of the downsizer workflow.

## Secrets

Do not commit any of the following:

- Radarr API key
- Discord webhook URL
- Any historical Home Assistant long-lived token

The Discord webhook is kept only in the protected local `discord_webhook` file. The temporary Home Assistant token used during notification testing was revoked after Discord became the final notification path.
