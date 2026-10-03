# Actual Budget Operations and Simplifi Migration

## Overview

Actual Budget is the homelab's self-hosted budgeting and account-management platform. It is deployed on the UGREEN NAS through Portainer. Routine remote access is restricted to Tailscale.

This document records the live architecture, the validated Simplifi migration workflow, SimpleFIN synchronization, and the custom Actual Helpers automations used for investment, debt, and 401(k) loan tracking.

## Architecture

```text
Tailscale client
  -> UGREEN NAS
  -> actual-budget container
  -> /volume1/docker/actual-budget/data

actual-auto-sync
  -> actual-budget:5006
  -> daily SimpleFIN import

actual-helpers
  -> Actual API
  -> investment, debt, and 401(k) loan tracking
```

The Actual stack is managed through Portainer. Companion containers use the internal Docker network to communicate with Actual where appropriate.

## Current Status

- Actual server deployed and healthy
- Actual Budget 26.8.0 validated
- Routine remote access restricted to Tailscale
- Simplifi historical migration completed and retained as migration documentation
- SimpleFIN connected and operational
- `actual-auto-sync` runs daily at 06:30 Central
- `actual-helpers` provides investment, debt, and 401(k) loan tracking
- Investment helper runs daily at 06:45 Central
- Debt helper runs at 06:45 Central on the 4th of each month
- 401(k) loan helper runs daily at 07:00 Central
- Helper scripts include logging and recovery for Actual out-of-sync cache errors

## Automation Schedule

Current host cron entries related to Actual:

```cron
45 6 * * * /volume1/docker/actual-helpers/scripts/run-track-investments.sh
45 6 4 * * /volume1/docker/actual-helpers/scripts/run-track-debts.sh
0 7 * * * /volume1/docker/actual-helpers/scripts/run-track-401k-loan.sh
```

The SimpleFIN companion container independently runs its daily sync at 06:30 Central. The staggered schedule gives SimpleFIN time to import current transactions before the helper scripts inspect the budget.

## Actual Helpers

The `actual-helpers` container uses scripts stored on the NAS under:

```text
/volume1/docker/actual-helpers/scripts/
```

Current helper scripts include:

- `track-investments.js` / `run-track-investments.sh`
- `track-debts.js` / `run-track-debts.sh`
- `track-401k-loan.js` / `run-track-401k-loan.sh`

The helpers use a persistent Actual cache under:

```text
/volume1/docker/actual-budget/helpers-cache
```

Runner scripts log executions, rotate logs at 5 MB, detect `SyncError: out-of-sync`, move the stale local budget cache aside, and retry once with a fresh cache.

### 401(k) loan tracking

The 401(k) loan is maintained as an off-budget liability named `401k Loan - Tracking`.

Beginning 2026-10-15, `track-401k-loan.js` looks for qualifying payroll deposits in `Checking` with:

- Payee: `RR Donnelley`
- Category: `Salary`

For each qualifying paycheck, the helper records a `$87.90` positive adjustment in the tracking account using the paycheck's transaction date. The helper uses the source paycheck transaction ID for idempotency so the same paycheck cannot be processed twice.

The automation deliberately follows imported payroll transactions instead of assuming a fixed biweekly calendar. If a paycheck arrives after the 07:00 run, a later run discovers it and records the adjustment using the original paycheck date.

The helper is bind-mounted into the container:

```yaml
- /volume1/docker/actual-helpers/scripts/track-401k-loan.js:/usr/src/app/track-401k-loan.js:ro
```

Log:

```text
/volume1/docker/actual-budget/helpers-cache/track-401k-loan.log
```

Current balances and transaction history remain intentionally excluded from Git.

## Simplifi Export Procedure

Use the Simplifi web application.

For each transaction-based account:

1. Open the account.
2. Select the **All** tab, not **Spending** or **Income**.
3. Open the transaction-list menu beside **Filter** and **New**.
4. Export all available transactions to CSV.
5. Preserve the original CSV without editing it.
6. Store exports outside the public Git repository.

Exporting from the Spending report produces an expense-only file and omits deposits. That failure mode was caught during the first checking-account test import.

### Sensitive-data rule

Never commit any of the following:

- Simplifi CSV exports
- Actual budget files or databases
- Account numbers
- Current balances
- Transaction history
- SimpleFIN tokens
- Bank credentials

Configuration values required to reproduce an automation may be documented when they do not expose credentials, account numbers, current balances, or transaction-history dumps.

## Actual CSV Import Mapping

Create a local Actual account with an initial balance of `0` and select **Import**.

Recommended mapping:

| Actual field | Simplifi CSV column |
| --- | --- |
| Date | Date |
| Payee | Payee |
| Notes | Leave unmapped when possible |
| Category | Category |
| Amount | Amount |

Amount options:

- Do not flip the amount
- Do not multiply the amount
- Do not split into separate inflow/outflow columns

Validation before import:

- Preview includes positive deposits and negative expenses
- Preview transaction count equals CSV data rows excluding the header
- Oldest transaction date matches the export
- Date preview parses correctly

## Opening-Balance Reconciliation

A CSV export contains transactions but may not contain the balance that existed before the first exported transaction.

After importing all available history:

```text
Opening balance = current institution balance - imported Actual balance
```

Create one transaction dated one day before the oldest imported transaction:

- Payee: `Simplifi Opening Balance`
- Category: `Starting Balances`
- Amount: calculated difference
- Cleared: yes

The purpose is to anchor the imported ledger to the balance that already existed when Simplifi tracking began. This is not missing money or an artificial adjustment when the exported history begins after the account was opened.

After adding the opening balance, confirm Actual's account balance matches Simplifi and the institution.

## Validated Checking Migration

The checking migration established the repeatable workflow:

1. An initial export from the Spending tab contained only expenses and was discarded.
2. The account was force-closed in Actual because it was a disposable test import.
3. A full export from the All tab contained both deposits and expenses.
4. The CSV row count matched Actual's import count.
5. The imported balance was reconciled using a dated `Simplifi Opening Balance` transaction.
6. The final Actual balance matched Simplifi.

Specific transaction details and balances are intentionally excluded from Git.

## Transfers and Off-Budget Liabilities

Pair corresponding transactions as transfers when both sides are represented by on-budget accounts. A credit-card payment is a transfer, not new spending; the card purchase is the spending event.

Off-budget liabilities are different. Payments may be categorized from checking while the off-budget balance is tracked or reconciled separately to account for principal, interest, or payroll deductions.

The 401(k) loan automation follows this pattern: the paycheck is the trigger, but the tracking adjustment is not represented as a false transfer out of checking.

## SimpleFIN Synchronization

SimpleFIN is connected and operational. Historical accounts were linked to their existing Actual accounts rather than duplicated.

The `actual-auto-sync` companion container:

- Runs daily at 06:30 Central
- Uses the internal Docker endpoint `http://actual-budget:5006`
- Imports the newest data already available from SimpleFIN
- Does not force financial institutions to refresh upstream data
- Uses `RUN_ON_START=false` after validation

Manual sync remains available when a specific transaction is expected before the next scheduled run.

## Legacy Browser and Proxy Troubleshooting

Actual previously used Nginx Proxy Manager and Cloudflare Tunnel for public HTTPS access. Routine access has since moved to Tailscale, but the following notes are retained for historical troubleshooting.

### Fatal SharedArrayBuffer error

When using an HTTPS reverse proxy, Actual requires:

```text
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

If those headers are present and Firefox Private Browsing works, clear normal-profile data for the site. Stale browser storage may be the cause.

### Historical NPM guidance

The previous NPM configuration kept only:

```nginx
client_max_body_size 100M;
```

Do not inject duplicate cross-origin headers when the Actual server already supplies them.

## Backup and Recovery

Persistent Actual data:

```text
/volume1/docker/actual-budget/data
```

Helper cache:

```text
/volume1/docker/actual-budget/helpers-cache
```

The persistent Actual data directory must remain in the existing backup policy. Before bulk imports, upgrades, bank-link changes, or encryption changes, create a point-in-time backup.

Restore outline:

1. Stop the Actual container.
2. Restore the complete data directory.
3. Confirm ownership and permissions.
4. Start the container.
5. Validate login, budget availability, balances, SimpleFIN sync, and helper operation.

Helper cache data is disposable synchronization state. When an Actual helper encounters an out-of-sync cache, its runner moves the stale budget cache aside and retries once with a fresh cache.

## Security Notes

- Routine remote access is restricted to Tailscale.
- Store encryption and server passwords in the password manager.
- Keep SimpleFIN tokens and server files in protected storage and never commit them to Git.
- Do not commit account numbers, current balances, exported transaction history, or Actual database files.

## Related Files

- [`../changes/2026-08-04-actual-budget-auto-sync-and-cloudflare-migrations.md`](../changes/2026-08-04-actual-budget-auto-sync-and-cloudflare-migrations.md)
- [`../changes/2026-10-03-actual-budget-401k-loan-tracking.md`](../changes/2026-10-03-actual-budget-401k-loan-tracking.md)
- [`../networking/tailscale.md`](../networking/tailscale.md)
- [`homelab-backup-and-disaster-recovery.md`](homelab-backup-and-disaster-recovery.md)
