# Actual Budget Auto-Sync and Migration Troubleshooting

Date: 2026-08-04

## Summary

Actual Budget was upgraded from 26.6.0 to 26.8.0, automated SimpleFIN imports were added through the `actual-auto-sync` companion container, and a Cloudflare WAF rule was corrected after it blocked Actual database migration assets.

## Changes Made

- Upgraded Actual Budget to the current `latest` image.
- Added `seriouslag/actual-auto-sync` as a second service in the same Portainer stack.
- Configured daily account sync for 06:30 Central.
- Kept `RUN_ON_START=false` after successful testing.
- Used the internal Docker endpoint `http://actual-budget:5006` for companion-to-server traffic.
- Disabled unattended Watchtower updates with labels on both containers.
- Adopted on-demand Watchtower updates for Actual.
- Added a Cloudflare WAF skip rule for `actual.armouredcore.net`.
- Confirmed Firefox client and Actual server both reached version 26.8.0.
- Confirmed the budget database opened successfully after migration files were unblocked.

## Root Cause: Database Would Not Open

The original symptoms included:

```text
Update required
Error updating budget
near "<": syntax error
```

Firefox DevTools showed Actual migration `.sql` requests returning `403 Forbidden`. Opening a migration URL directly displayed a Cloudflare block page.

Actual expected SQL but received Cloudflare HTML beginning with `<`, which SQLite attempted to parse and rejected.

The database itself was not corrupted. Cloudflare managed security incorrectly treated requests for legitimate migration SQL files as suspicious traffic.

## Cloudflare Fix

A WAF skip rule was added with this condition:

```text
Hostname equals actual.armouredcore.net
```

Skipped components:

- Remaining custom rules
- Rate limiting rules
- Managed rules
- Super Bot Fight Mode rules
- Browser Integrity Check

The rule was placed early in execution order. After propagation, migration URLs returned SQL successfully and Actual completed the client-side migration.

## Auto-Sync Findings

The companion container successfully resolved the service hostname to a Docker network address and reached Actual internally.

The minimal image did not include `curl` or `wget`, so Node was used for testing:

```bash
node -e "require('dns').lookup('actual-budget', console.log)"
node -e "fetch('http://actual-budget:5006').then(r => console.log('HTTP', r.status)).catch(err => { console.error(err); process.exit(1); })"
```

A successful test run logged:

```text
Account balances synced through CRDT.
Budget synced to server successfully.
Accounts synced successfully for budget ...
Cron job completed.
```

The companion does not force SimpleFIN to refresh banks. It only imports the newest data already available from SimpleFIN.

## Current Update Policy

Actual tracks the `latest` image, but Watchtower automatic updates remain disabled:

```yaml
com.centurylinklabs.watchtower.enable=false
```

Updates are performed manually after a cold backup:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once actual-budget
```

## Backup and Rollback Lesson

Before upgrading:

1. Export the budget from Actual.
2. Stop Actual.
3. Copy or archive `/volume1/docker/actual-budget/data`.
4. Upgrade and verify the client, server, migrations, balances, schedules, and bank sync.

Rollback after a database migration requires restoring the pre-upgrade data backup. Merely switching the image tag back may not be sufficient.

## Budgeting Workflow Decisions

- Tracking Budgeting was selected because it more closely matches the prior Simplifi workflow.
- Historical imported transfers may remain categorized under hidden cleanup categories when matching account history does not exist.
- Credit-card payments are transfers, not expenses.
- Loan payments are categorized from checking, while off-budget loan balances are reconciled to lender values to absorb principal and interest differences.
- SimpleFIN and Actual daily sync are sufficient for routine use, with manual sync available when a specific transaction is expected.
