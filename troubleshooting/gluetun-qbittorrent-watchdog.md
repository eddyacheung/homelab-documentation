# Gluetun and qBittorrent Recovery Watchdog

## Purpose

This runbook documents the automatic recovery workflow for the Gluetun VPN container and the qBittorrent container that shares its network namespace.

The watchdog runs once per minute from root's crontab. When Gluetun becomes unhealthy, it attempts multiple container restarts until the VPN is healthy. After Gluetun recovers, it restarts qBittorrent so qBittorrent reconnects cleanly through the restored VPN namespace.

## Environment

- Host: UGREEN DXP4800 Plus
- Gluetun container: `gluetun`
- qBittorrent container: `qbittorrent`
- Recovery directory: `/volume1/docker/qbittorrent-recovery`
- Watchdog script: `/volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh`
- State file: `/volume1/docker/qbittorrent-recovery/gluetun-started-at`
- Lock directory: `/volume1/docker/qbittorrent-recovery/run.lock`
- Log file: `/volume1/docker/qbittorrent-recovery/recovery.log`

## Incident Summary

On 2026-08-02, Gluetun remained unhealthy while repeatedly failing its startup health check. The container logs showed transient NordVPN OpenVPN authentication failures and DNS lookup timeouts. Manual restarts eventually restored a healthy VPN connection.

The existing recovery script did not restart an unhealthy Gluetun container. It only detected that Gluetun had already restarted, waited for Gluetun to become healthy, and then restarted qBittorrent. Because the Gluetun start timestamp did not change while the container remained unhealthy, the script exited without taking action.

The cron scheduler itself was working correctly:

```cron
* * * * * /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
```

## Root Cause

The original script was a qBittorrent companion-restart script rather than a complete Gluetun health watchdog.

Its effective behavior was:

1. Read Gluetun's current container start timestamp.
2. Compare it with the saved timestamp.
3. Exit when the timestamps matched.
4. When the timestamp changed, wait for Gluetun to become healthy.
5. Restart qBittorrent after Gluetun recovered.

It did not inspect Gluetun health and initiate a Gluetun restart when the start timestamp was unchanged.

## Final Watchdog Script

```sh
#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

STATE_DIR="/volume1/docker/qbittorrent-recovery"
STATE_FILE="$STATE_DIR/gluetun-started-at"
LOCK_DIR="$STATE_DIR/run.lock"
LOG_FILE="$STATE_DIR/recovery.log"

GLUETUN_CONTAINER="gluetun"
QBITTORRENT_CONTAINER="qbittorrent"

MAX_RESTARTS=5
HEALTH_ATTEMPTS=12
HEALTH_INTERVAL=5

log_message() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

get_started_at() {
    docker inspect \
        --format '{{.State.StartedAt}}' \
        "$GLUETUN_CONTAINER" 2>/dev/null
}

get_health() {
    docker inspect \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
        "$GLUETUN_CONTAINER" 2>/dev/null
}

wait_for_healthy() {
    attempt=1

    while [ "$attempt" -le "$HEALTH_ATTEMPTS" ]; do
        health_status="$(get_health)"

        if [ "$health_status" = "healthy" ]; then
            return 0
        fi

        sleep "$HEALTH_INTERVAL"
        attempt=$((attempt + 1))
    done

    return 1
}

restart_qbittorrent() {
    if docker restart "$QBITTORRENT_CONTAINER" >/dev/null 2>&1; then
        log_message "SUCCESS: Restarted qBittorrent after Gluetun recovery."
        return 0
    fi

    log_message "ERROR: Failed to restart qBittorrent."
    return 1
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT INT TERM

current_started_at="$(get_started_at)"

if [ -z "$current_started_at" ]; then
    log_message "ERROR: Could not inspect Gluetun."
    exit 1
fi

health_status="$(get_health)"
previous_started_at="$(cat "$STATE_FILE" 2>/dev/null)"

if [ ! -f "$STATE_FILE" ]; then
    printf '%s\n' "$current_started_at" > "$STATE_FILE"
    previous_started_at="$current_started_at"
    log_message "Initialized watchdog state with Gluetun health '$health_status'."
fi

if [ "$health_status" = "healthy" ]; then
    if [ "$current_started_at" != "$previous_started_at" ]; then
        log_message "Detected a healthy Gluetun restart; restarting qBittorrent."

        restart_qbittorrent || exit 1
        printf '%s\n' "$current_started_at" > "$STATE_FILE"
    fi

    exit 0
fi

log_message "WARNING: Gluetun health is '$health_status'; beginning automatic recovery."

restart_attempt=1

while [ "$restart_attempt" -le "$MAX_RESTARTS" ]; do
    log_message "Restarting Gluetun, attempt $restart_attempt of $MAX_RESTARTS."

    if ! docker restart "$GLUETUN_CONTAINER" >/dev/null 2>&1; then
        log_message "ERROR: Docker failed to restart Gluetun."
        restart_attempt=$((restart_attempt + 1))
        continue
    fi

    if wait_for_healthy; then
        current_started_at="$(get_started_at)"
        printf '%s\n' "$current_started_at" > "$STATE_FILE"

        log_message "SUCCESS: Gluetun became healthy on attempt $restart_attempt."

        restart_qbittorrent || exit 1
        exit 0
    fi

    health_status="$(get_health)"
    log_message "WARNING: Gluetun remained '$health_status' after attempt $restart_attempt."

    restart_attempt=$((restart_attempt + 1))
done

log_message "ERROR: Gluetun failed to recover after $MAX_RESTARTS restart attempts."
exit 1
```

## Watchdog Behavior

### Healthy and unchanged

When Gluetun is healthy and its start timestamp matches the state file, the script exits without logging or restarting containers.

### Healthy after a manual or external restart

When Gluetun is healthy but its start timestamp changed, the script restarts qBittorrent and records the new Gluetun start timestamp.

### Unhealthy

When Gluetun reports any status other than `healthy`, the script:

1. Restarts Gluetun.
2. Checks health every five seconds for up to 60 seconds.
3. Repeats up to five Gluetun restart attempts.
4. Records the new start timestamp after recovery.
5. Restarts qBittorrent.
6. Exits with a failure code if Gluetun does not recover after five attempts.

### Locking

The script creates `run.lock` as a directory. A second cron invocation exits while an earlier recovery run is active. The `trap` removes the lock when the script exits normally or receives a termination signal.

Remove a stale lock manually with:

```bash
rm -rf /volume1/docker/qbittorrent-recovery/run.lock
```

## Installation and Scheduling

Confirm the script is executable:

```bash
chmod 750 /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
```

Root's crontab must contain:

```cron
* * * * * /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
```

Review it with:

```bash
crontab -l
```

## Validation

### Syntax check

```bash
sh -n /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
echo "Syntax exit code: $?"
```

Expected:

```text
Syntax exit code: 0
```

### Manual healthy-state run

```bash
rm -rf /volume1/docker/qbittorrent-recovery/run.lock
/volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
echo "Script exit code: $?"
```

Expected:

```text
Script exit code: 0
```

### Container status

```bash
docker ps --filter name=gluetun --filter name=qbittorrent \
  --format 'table {{.Names}}\t{{.Status}}'
```

Expected final state:

```text
NAMES         STATUS
qbittorrent   Up ...
gluetun       Up ... (healthy)
```

### Recovery log

```bash
tail -20 /volume1/docker/qbittorrent-recovery/recovery.log
```

Successful incident validation on 2026-08-02:

```text
2026-08-02 23:04:01 WARNING: Gluetun health is 'unhealthy'; beginning automatic recovery.
2026-08-02 23:04:01 Restarting Gluetun, attempt 1 of 5.
2026-08-02 23:05:02 WARNING: Gluetun remained 'unhealthy' after attempt 1.
2026-08-02 23:05:02 Restarting Gluetun, attempt 2 of 5.
2026-08-02 23:05:13 SUCCESS: Gluetun became healthy on attempt 2.
2026-08-02 23:05:16 SUCCESS: Restarted qBittorrent after Gluetun recovery.
```

This confirms that the watchdog detected the unhealthy state, retried Gluetun, recovered on its second restart attempt, and restarted qBittorrent afterward.

## Troubleshooting Commands

Inspect Gluetun health:

```bash
docker inspect gluetun --format \
'Health={{.State.Health.Status}} Started={{.State.StartedAt}}'
```

Inspect recent Gluetun logs:

```bash
docker logs gluetun --tail 150
```

Inspect the saved timestamp:

```bash
cat /volume1/docker/qbittorrent-recovery/gluetun-started-at
```

Inspect cron execution:

```bash
systemctl status cron --no-pager
journalctl --since "2 hours ago" --no-pager \
  | grep -Ei 'cron|recover-qbittorrent|gluetun'
```

Trace a manual script run:

```bash
bash -x /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
```

## Important Notes

- qBittorrent uses Gluetun's Docker network namespace. qBittorrent should be restarted after Gluetun restarts so it reconnects cleanly through the restored namespace.
- An unhealthy Gluetun container preserves the VPN kill-switch behavior, but qBittorrent will have no usable network connection until Gluetun recovers.
- Repeated `AUTH_FAILED` messages can be transient when subsequent restarts succeed. Persistent failures across all restart attempts should trigger a review of NordVPN manual-service credentials, account status, VPN server selection, and provider availability.
- The watchdog intentionally limits recovery to five restart attempts to avoid an endless restart loop during a prolonged provider outage or configuration failure.

## Rollback

Backups of earlier scripts use this naming pattern:

```text
recover-qbittorrent.sh.bak-YYYYMMDD-HHMMSS
```

List available backups:

```bash
ls -lah /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh.bak-*
```

Restore a selected backup:

```bash
cp -a \
  /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh.bak-YYYYMMDD-HHMMSS \
  /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh

chmod 750 /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
rm -rf /volume1/docker/qbittorrent-recovery/run.lock
sh -n /volume1/docker/qbittorrent-recovery/recover-qbittorrent.sh
```
