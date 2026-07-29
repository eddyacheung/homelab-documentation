# Actual Budget v26.7.0 Migration Regression and Recovery

**Date:** 2026-07-29  
**Service:** Actual Budget  
**Host:** UGREEN NAS  
**Container:** `actual-budget`  
**Status:** Resolved by rollback to v26.6.0

## Summary

Actual Budget stopped opening the encrypted budget after the container was updated to v26.7.0. The browser accepted the encryption password, downloaded the budget, and then failed while applying a client-side database migration.

The budget data was not lost. Both server-side SQLite databases passed integrity checks, the encrypted budget blob remained present, and all encryption metadata was intact. Rolling the container back from v26.7.0 to v26.6.0 restored access to the same budget and data directory.

## User-visible symptoms

The web interface remained on the loading screen and displayed:

```text
We had an unknown problem opening "My-Finances-2149866".
```

Firefox Developer Tools showed the underlying failure:

```text
Error updating budget My-Finances-2149866 Error: near "<": syntax error
applyMigration
```

After the rollback, Actual initially displayed a generic internal-error notification, but Budget, Reports, and Schedules loaded normally after refreshing the page.

## Environment

```text
Container: actual-budget
Image before recovery: actualbudget/actual-server:latest
Failing application/server version: 26.7.0
Working image after recovery: actualbudget/actual-server:26.6.0
Published port: 5006
Data mount: /volume1/docker/actual-budget/data -> /data
Public hostname: actual.armouredcore.net
```

Cloudflare Access, Cloudflare Tunnel, Nginx Proxy Manager, and Firefox were part of the access path but were not the root cause.

## Investigation

### 1. Confirmed the container was healthy

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
docker logs actual-budget --tail 150
```

The server completed its startup migrations and listened normally on port 5006. Sync endpoints returned successful HTTP responses.

### 2. Verified the persistent mount

```bash
docker inspect actual-budget \
  --format '{{range .Mounts}}{{println .Type ":" .Source "->" .Destination}}{{end}}'
```

Confirmed:

```text
/volume1/docker/actual-budget/data -> /data
```

### 3. Verified the budget files existed

```bash
docker exec actual-budget ls -lah /data/user-files
```

The following files were present:

```text
file-b78d12e0-3d56-4901-8a66-ea77f0ec5ad4.blob
group-43495e99-3eb2-4f97-9a83-b52512c2df37.sqlite
```

The encrypted budget blob was approximately 470 KB and the group database was approximately 16 KB.

### 4. Verified SQLite integrity

A Python read-only integrity check was run against both databases:

```python
import sqlite3
from pathlib import Path

base = Path("/volume1/docker/actual-budget/data")
account_db = base / "server-files/account.sqlite"
group_db = base / "user-files/group-43495e99-3eb2-4f97-9a83-b52512c2df37.sqlite"

for path in (account_db, group_db):
    con = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    print(path, con.execute("PRAGMA integrity_check").fetchone()[0])
    con.close()
```

Both returned:

```text
ok
```

### 5. Verified encryption metadata

The `files` record in `account.sqlite` contained all expected encryption fields:

- `encrypt_meta`
- `encrypt_keyid`
- `encrypt_salt`
- `encrypt_test`

The budget record was not marked deleted.

### 6. Eliminated Cloudflare and browser storage

The following were tested and ruled out:

- Cloudflare Bot Fight Mode disabled temporarily
- Cloudflare Access bypassed temporarily
- Direct LAN HTTP test, which correctly failed because Actual requires a secure browser context
- Firefox private browsing
- Complete deletion of Firefox IndexedDB, Cache Storage, Local Storage, Session Storage, cookies, and service-worker data

The same migration error remained under v26.7.0.

## Root cause

The evidence indicates an Actual Budget v26.7.0 regression affecting this budget's client-side migration path.

This conclusion is based on the controlled rollback result:

- v26.7.0 failed consistently with `near "<": syntax error` during `applyMigration`.
- v26.6.0 opened the exact same encrypted budget.
- The same server-side data directory and encryption password were used.
- Both SQLite databases passed integrity checks.

The precise upstream code defect was not identified during recovery, so this should be treated as a version-specific regression rather than a fully characterized application bug.

## Recovery procedure

### 1. Back up the data directory

```bash
mkdir -p /volume1/backups/actual-budget

tar -czf \
  /volume1/backups/actual-budget/actual-before-rollback-$(date +%Y%m%d-%H%M%S).tar.gz \
  -C /volume1/docker/actual-budget data
```

### 2. Pull the known-working image

```bash
docker pull actualbudget/actual-server:26.6.0
```

### 3. Update the Portainer stack

In Portainer, open:

```text
Stacks -> actual-budget -> Editor
```

Change:

```yaml
image: actualbudget/actual-server:latest
```

to:

```yaml
image: actualbudget/actual-server:26.6.0
```

Disable Watchtower for this service:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=false
```

Redeploy the stack without changing the data mount.

### 4. Verify the running image

```bash
docker inspect actual-budget --format '{{.Config.Image}}'
docker logs actual-budget --tail 50
```

Expected image:

```text
actualbudget/actual-server:26.6.0
```

### 5. Validate the application

Confirm all of the following:

- Budget unlocks with the encryption password
- Accounts and balances appear
- Budget view loads
- Reports load
- Schedules load
- Server status shows online

### 6. Create recovery exports

After access is restored:

1. Export the budget from Actual.
2. Store the export outside the container data directory.
3. Create a fresh filesystem backup of `/volume1/docker/actual-budget/data`.

## Current operating policy

Actual Budget remains pinned to:

```yaml
image: actualbudget/actual-server:26.6.0
```

Watchtower remains disabled for this container.

Actual Budget should be treated as a stateful financial application and upgraded manually only.

## Future upgrade procedure

Before upgrading Actual Budget:

1. Export the budget from the application.
2. Create a timestamped archive of `/volume1/docker/actual-budget/data`.
3. Record the currently working image tag.
4. Pull a specific version tag, not `latest`.
5. Redeploy manually.
6. Confirm the encrypted budget opens.
7. Confirm Budget, Reports, Schedules, accounts, and balances load.
8. Review the browser console for migration errors.
9. Keep the new version only after validation.
10. Roll back immediately if the budget fails to open.

Suggested backup command:

```bash
mkdir -p /volume1/backups/actual-budget

tar -czf \
  /volume1/backups/actual-budget/actual-pre-upgrade-$(date +%Y%m%d-%H%M%S).tar.gz \
  -C /volume1/docker/actual-budget data
```

Suggested rollback pattern:

```yaml
image: actualbudget/actual-server:<last-known-working-version>
```

## Lessons learned

- A healthy Docker container does not guarantee that an encrypted client-side budget migration will succeed.
- Server-side SQLite integrity checks can quickly distinguish data corruption from an application regression.
- Cloudflare Access and browser caching should be tested, but they were not responsible for this incident.
- Financial and database-backed applications should not use unattended floating-tag upgrades.
- Keep both application-level exports and filesystem-level backups.
