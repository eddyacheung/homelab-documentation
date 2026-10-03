# Actual Budget 401(k) Loan Tracking Automation

Date: 2026-10-03

## Summary

Added automated tracking for payroll-deducted 401(k) loan payments in Actual Budget.

The loan is maintained as an off-budget liability. A custom Actual Helpers script detects qualifying payroll deposits and records the corresponding loan reduction without creating a false transfer from checking.

## Implementation

- Tracking account: `401k Loan - Tracking`
- Account type: Off budget
- Helper: `track-401k-loan.js`
- Runner: `run-track-401k-loan.sh`
- Source account: `Checking`
- Payroll payee: `RR Donnelley`
- Payroll category: `Salary`
- Loan tracking payee: `401k Loan Payment`
- Loan payment: `$87.90` per qualifying paycheck
- Automation start date: `2026-10-15`
- Historical paychecks before the start date are ignored.
- The loan adjustment uses the source paycheck transaction date.
- Duplicate protection prevents a paycheck from being processed more than once.

Current loan balances and transaction history are intentionally excluded from Git.

## Scheduling

The helper runs daily at 07:00 Central:

```cron
0 7 * * * /volume1/docker/actual-helpers/scripts/run-track-401k-loan.sh
```

A daily schedule was chosen instead of a biweekly calendar schedule so the automation follows the actual imported paycheck rather than assuming a fixed payroll date.

The schedule follows the 06:30 SimpleFIN auto-sync and the 06:45 investment helper. If a paycheck has not imported by 07:00, a later daily run detects it and creates the loan adjustment using the original paycheck date.

## Container Integration

The helper script is bind-mounted into the existing `actual-helpers` container:

```yaml
- /volume1/docker/actual-helpers/scripts/track-401k-loan.js:/usr/src/app/track-401k-loan.js:ro
```

Persistent helper scripts are stored on the NAS under:

```text
/volume1/docker/actual-helpers/scripts/
```

The `actual-helpers` container remains part of the Portainer-managed Actual Budget stack.

## Duplicate Protection

Each generated loan adjustment is tied to the source paycheck transaction ID.

The helper uses a deterministic imported ID based on the paycheck ID and also records the paycheck ID in the transaction notes. Before creating an adjustment, it checks the existing loan transactions for either marker.

This makes repeated daily executions idempotent: once a paycheck has been processed, later runs skip it.

## Reliability

`run-track-401k-loan.sh` follows the same recovery pattern as the existing investment and debt helpers:

- Logs each execution.
- Rotates the log at 5 MB.
- Detects Actual `SyncError: out-of-sync`.
- Moves the stale local budget cache aside.
- Retries once with a fresh cache.
- Returns a non-zero exit code when the helper or recovery attempt fails.

Log:

```text
/volume1/docker/actual-budget/helpers-cache/track-401k-loan.log
```

The normal helper cache is stored under:

```text
/volume1/docker/actual-budget/helpers-cache/My-Finances-2149866
```

When an out-of-sync cache is detected, the stale budget directory is moved aside with a timestamp before the retry.

## Validation

Initial testing on 2026-10-03 confirmed:

- JavaScript syntax validation completed successfully.
- The helper successfully opened and synced the Actual budget.
- No historical paycheck was processed.
- No transaction was created before the `2026-10-15` boundary.
- The helper exited successfully with code `0`.
- The shell runner completed successfully and wrote to its log.
- The final root crontab contains one 07:00 entry for the helper.

The first production payroll-triggered adjustment is expected on or after 2026-10-15. After the first qualifying paycheck, run the helper twice or inspect consecutive scheduled runs to confirm the second execution reports the paycheck as already processed and creates no duplicate.
