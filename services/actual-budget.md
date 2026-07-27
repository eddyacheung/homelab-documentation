# Actual Budget Operations and Simplifi Migration

## Overview

Actual Budget is the homelab's self-hosted budgeting and account-management platform. It is deployed on the UGREEN NAS through Portainer and accessed through Nginx Proxy Manager and Cloudflare Tunnel.

This document records the live architecture, the validated Simplifi migration workflow, the opening-balance reconciliation method, and the planned SimpleFIN integration.

## Architecture

```text
Browser
  -> https://actual.armouredcore.net
  -> Cloudflare Tunnel
  -> nginx-proxy-manager:80
  -> 192.168.10.101:5006
  -> actual-budget container
  -> /volume1/docker/actual-budget/data
```

The direct HTTP endpoint is not suitable for normal browser use because Actual requires HTTPS and cross-origin isolation for `SharedArrayBuffer`.

## Current Status

- Actual server deployed and healthy
- Public HTTPS hostname operational
- Nginx Proxy Manager route operational
- Required cross-origin headers validated through `curl.exe -I`
- Firefox stale-site-data issue identified and resolved
- Simplifi transaction export workflow validated
- Checking-account history imported and reconciled
- SimpleFIN not yet connected
- Cloudflare Access remains a security follow-up

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
- Payees or transaction history
- SimpleFIN tokens
- Bank credentials

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

## Remaining Migration Order

Recommended sequence:

1. Remaining checking and savings accounts
2. HSA
3. Active credit cards
4. Store and revolving-credit accounts
5. Manually tracked liabilities
6. Investment and retirement accounts
7. SimpleFIN connection
8. Transfer repair and categorization rules
9. Recurring schedules and budget targets

Inactive zero-balance accounts should be migrated only when their historical data is useful.

## Transfers

Do not finalize categories until both sides of major transfers are present.

Examples include:

- Checking to savings
- Checking to credit card
- Checking to loan
- PayPal or Apple Cash transfers

Once both accounts exist, pair corresponding transactions as transfers where appropriate. A credit-card payment is a transfer, not new spending; the card purchase is the spending event.

## SimpleFIN Plan

Connect SimpleFIN only after historical imports and balance reconciliation are complete.

For each SimpleFIN account:

1. Link it to the existing Actual account that contains imported history.
2. Do not create a duplicate account.
3. Sync one account first.
4. Review the overlapping recent period for duplicate pending and posted transactions.
5. Confirm the cleared balance and new transaction flow.
6. Continue account by account.

Use the monthly SimpleFIN plan during the validation period before switching to annual billing.

## Browser and Proxy Troubleshooting

### Fatal SharedArrayBuffer error

Verify:

```powershell
curl.exe -I https://actual.armouredcore.net
```

Required headers:

```text
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

If they are present and Firefox Private Browsing works, clear normal-profile data for the site. The server and proxy are functioning; stale browser storage is the likely cause.

### NPM guidance

Keep only:

```nginx
client_max_body_size 100M;
```

Do not inject duplicate cross-origin headers when the Actual server already supplies them.

## Backup and Recovery

Persistent data:

```text
/volume1/docker/actual-budget/data
```

This directory must be added to the existing nightly backup policy. Before bulk imports, upgrades, bank-link changes, or encryption changes, create a point-in-time backup.

Restore outline:

1. Stop the Actual container.
2. Restore the complete data directory.
3. Confirm ownership and permissions.
4. Start the container.
5. Validate login, budget availability, balances, and sync state.

## Security Follow-ups

- Add Cloudflare Access authentication to `actual.armouredcore.net`, or move routine remote access to Tailscale only.
- Enable Actual budget encryption after migration validation.
- Store encryption and server passwords in the password manager.
- Confirm SimpleFIN tokens and server files are included in protected backups but never in Git.
- Review whether port `5006` should remain LAN-published after proxy validation.

## Related Files

- [`../docker/actual-budget/docker-compose.yml`](../docker/actual-budget/docker-compose.yml)
- [`../docker/actual-budget/README.md`](../docker/actual-budget/README.md)
- [`../networking/cloudflare-zero-trust.md`](../networking/cloudflare-zero-trust.md)
- [`nginx-proxy-manager.md`](nginx-proxy-manager.md)
- [`homelab-backup-and-disaster-recovery.md`](homelab-backup-and-disaster-recovery.md)
