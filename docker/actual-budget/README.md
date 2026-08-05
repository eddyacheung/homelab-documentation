# Actual Budget Stack

Self-hosted personal budgeting and account-management service deployed through Portainer on the UGREEN NAS.

## Purpose

Actual Budget provides a private, locally controlled replacement for hosted budgeting applications. The primary database is stored on the NAS, bank synchronization is provided through SimpleFIN, and a companion container triggers automatic daily imports.

## Deployment

- Actual image: `actualbudget/actual-server:latest`
- Actual container: `actual-budget`
- Auto-sync image: `seriouslag/actual-auto-sync:latest`
- Auto-sync container: `actual-auto-sync`
- Local port: `5006`
- Persistent data: `/volume1/docker/actual-budget/data`
- Time zone: `America/Chicago`
- Restart policy: `unless-stopped`
- Scheduled bank sync: daily at `06:30` Central

Both containers carry the label below so Watchtower does not update them automatically:

```yaml
com.centurylinklabs.watchtower.enable=false
```

Updates are intentionally performed on demand after a backup.

## Access

- Direct LAN endpoint: `http://192.168.10.101:5006`
- Normal browser endpoint: `https://actual.armouredcore.net`
- Internal container endpoint: `http://actual-budget:5006`

The internal hostname is resolvable only by containers attached to the same Compose network. It is not expected to work in a browser on another device.

The direct HTTP endpoint is useful only for basic connectivity checks. Actual requires a secure browser context for `SharedArrayBuffer`, so normal use must go through HTTPS.

## Dependencies

- Portainer
- Nginx Proxy Manager
- Cloudflare Tunnel
- Cloudflare DNS for `actual.armouredcore.net`
- SimpleFIN
- Actual Auto Sync companion container

The service does not require `media-net` or access to media-stack containers.

## Portainer Deployment

1. Create `/volume1/docker/actual-budget/data` on the NAS.
2. In Portainer, create a stack named `actual-budget`.
3. Add these stack environment variables in Portainer:
   - `ACTUAL_SERVER_PASSWORD`
   - `ACTUAL_BUDGET_SYNC_IDS`
   - `ACTUAL_ENCRYPTION_PASSWORD` when budget encryption is enabled
4. Paste `docker-compose.yml` from this directory.
5. Deploy the stack.
6. Confirm both containers are running and `actual-budget` reports healthy.

Never commit real passwords, Sync IDs, encryption passwords, SimpleFIN setup tokens, exports, or budget databases.

## Verification

```bash
docker ps --filter name=actual-budget
docker ps --filter name=actual-auto-sync
docker logs actual-budget --tail 100
docker logs actual-auto-sync --tail 100
```

Test Docker DNS from the companion container with Node, because the minimal image may not contain `curl` or `wget`:

```bash
docker exec -it actual-auto-sync sh
node -e "require('dns').lookup('actual-budget', console.log)"
node -e "fetch('http://actual-budget:5006').then(r => console.log('HTTP', r.status)).catch(err => { console.error(err); process.exit(1); })"
exit
```

A resolved private IP and an HTTP response confirm container-to-container networking.

## Automatic Bank Sync

The companion container does not connect to banks directly. The flow is:

```text
Banks -> SimpleFIN -> Actual Server
                    ^
             actual-auto-sync
```

SimpleFIN refreshes upstream data on its own cadence, commonly about once per day. The companion merely asks Actual to import whatever SimpleFIN currently has.

Current schedule:

```yaml
CRON_SCHEDULE: "30 6 * * *"
TIMEZONE: "America/Chicago"
RUN_ON_START: "false"
```

To test immediately, temporarily set `RUN_ON_START` to `true`, redeploy in Portainer, verify a successful run, then set it back to `false`.

Successful logs include messages similar to:

```text
Account balances synced through CRDT.
Budget synced to server successfully.
Accounts synced successfully for budget ...
Cron job completed.
```

Repeated breadcrumb messages can appear in the logs and are harmless when the run finishes successfully.

## Reverse Proxy

Create an Nginx Proxy Manager proxy host with:

- Domain: `actual.armouredcore.net`
- Scheme: `http`
- Forward host: `192.168.10.101`
- Forward port: `5006`
- Block Common Exploits: enabled
- Websockets Support: enabled
- Cache Assets: disabled
- NPM SSL certificate: none, because Cloudflare Tunnel terminates public TLS

Advanced configuration:

```nginx
client_max_body_size 100M;
```

Do not add duplicate `Cross-Origin-Opener-Policy` or `Cross-Origin-Embedder-Policy` headers in NPM. The Actual server supplies them. Duplicate values can prevent cross-origin isolation and produce the fatal `SharedArrayBuffer` error.

## Cloudflare Tunnel and WAF

Published application route:

```text
actual.armouredcore.net -> http://nginx-proxy-manager:80
```

The browser-facing URL must remain HTTPS.

Cloudflare managed protection blocked Actual migration files ending in `.sql`. The browser then received a Cloudflare HTML block page instead of SQL, causing errors such as:

```text
near "<": syntax error
Error updating budget
```

The Network panel showed migration requests returning `403 Forbidden`.

A Cloudflare WAF skip rule is required for the Actual hostname:

```text
Hostname equals actual.armouredcore.net
```

Skip these components for that hostname:

- All remaining custom rules
- All rate limiting rules
- All managed rules
- All Super Bot Fight Mode rules
- Browser Integrity Check

Place the rule early in execution order. Keep logging enabled. Verify a migration URL returns plain SQL rather than a Cloudflare block page.

This rule must remain in place for future Actual upgrades because new releases may add additional migration `.sql` files.

## SharedArrayBuffer Troubleshooting

Expected response headers:

```text
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

Verify from Windows:

```powershell
curl.exe -I https://actual.armouredcore.net
```

If the headers are present but Firefox still displays a fatal error or an outdated client version:

1. Test the site in a Firefox Private Window.
2. Clear stored site data for `actual.armouredcore.net`.
3. Unregister the site service worker if necessary.
4. Reload and verify client and server versions match.

After upgrading the server, an old cached Firefox client may continue to report the prior version until site data is cleared.

## Budget Migration Notes

Tracking Budgeting was selected instead of Envelope Budgeting because the imported Simplifi history created large historical envelope balances and an unrealistic `To Budget` amount. Tracking Budgeting better matches the desired Simplifi-style workflow:

- Monthly planned spending
- Reports and net-worth tracking
- No requirement to assign every available dollar
- Historical transactions retained without reconstructing every past envelope

Investment and loan accounts are maintained off-budget for net-worth tracking. Loan payments remain categorized in the checking account, while loan tracking balances are reconciled periodically to the lender-reported balance to account for principal and interest without manually maintaining amortization splits.

Credit-card payments are transfers, not expenses. Purchases receive spending categories when charged; paying the card merely moves money from checking to the credit-card account.

## Security

- Use a strong, unique Actual server password.
- Use a separate strong budget encryption password.
- Do not expose port `5006` through the router.
- Tailscale remains the preferred private remote-access path when public access is unnecessary.
- Never commit financial exports, account numbers, Sync IDs, tokens, passwords, or budget databases.
- Keep Watchtower disabled for unattended updates of this stack.

## Backup

Create both an application export and a cold filesystem backup before upgrades or major changes.

Application-level backup:

```text
Actual -> Settings -> Export Data
```

Cold directory copy:

```bash
docker stop actual-budget
cp -a /volume1/docker/actual-budget/data \
  /volume1/docker/actual-budget/data-backup-$(date +%Y%m%d-%H%M%S)
docker start actual-budget
```

Compressed archive:

```bash
docker stop actual-budget
tar -czf /volume1/docker/actual-budget/actual-budget-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  -C /volume1/docker/actual-budget data
docker start actual-budget
```

Verify the backup exists and is nonzero before continuing.

Rollback requires restoring the pre-upgrade data copy. Do not assume changing the image tag backward is enough after a newer release has migrated the database.

## Upgrade Workflow

The stack tracks `latest`, but Watchtower updates are disabled. Upgrades are deliberate:

1. Review release notes.
2. Stop `actual-auto-sync`.
3. Export the budget from Actual.
4. Back up `/volume1/docker/actual-budget/data` while Actual is stopped.
5. Run an on-demand Watchtower update for only Actual:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once actual-budget
```

6. Open Actual in a Private Window or clear the browser cache.
7. Confirm client and server versions match.
8. Verify balances, transactions, schedules, manual bank sync, and Cloudflare migration requests.
9. Restart `actual-auto-sync` and confirm its next scheduled run.

The preferred policy is on-demand Watchtower updates, never unattended updates, for the financial stack.
