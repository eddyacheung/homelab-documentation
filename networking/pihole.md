# Pi-hole

## Purpose

Pi-hole provides local DNS filtering, ad blocking, and local DNS records for the homelab.

It is used as the primary DNS resolver for selected devices and networks.

## Local DNS

Pi-hole hosts local DNS records for homelab services so they can be accessed with friendly `.home` hostnames instead of IP addresses and ports.

Examples:

- `ugreen.home`
- `seerr.home`
- `sonarr.home`
- `radarr.home`
- `qbt.home`

## Upstream DNS

Pi-hole forwards upstream DNS queries to the local Unbound container:

```text
server=unbound#53
```

DNS flow:

```text
Clients
  ↓
Pi-hole
  ↓
Unbound
  ↓
Recursive DNS resolution
```

## Verification Commands

Verify Pi-hole container health:

```bash
docker ps --filter name=pihole
```

Verify Pi-hole forwards to Unbound:

```bash
docker exec pihole grep -R "server=" /etc/dnsmasq.d /etc/pihole 2>/dev/null
```

Expected result:

```text
/etc/pihole/dnsmasq.conf:server=unbound#53
```

Verify Pi-hole can resolve external domains:

```bash
docker exec pihole nslookup cloudflare.com 127.0.0.1
```

Verify Unbound can resolve directly:

```bash
docker exec unbound drill @127.0.0.1 cloudflare.com
```

## Pi-hole + Unbound Audit

Audit completed on 2026-06-28.

Confirmed:

- Pi-hole container is healthy.
- Unbound container is healthy.
- Pi-hole forwards DNS queries to `unbound#53`.
- Pi-hole resolves external domains successfully.
- Unbound resolves external domains directly.
- No configuration changes were required during the audit.

## Overwatch Fails to Launch Behind Pi-hole

### Symptoms

- Overwatch launched from Steam does not start.
- Disabling Pi-hole immediately resolves the issue.

### Cause

Aggressive Pi-hole blocklists may block Blizzard authentication or CDN domains.

### Resolution

Add the following domains to the Pi-hole allowlist:

- `battle.net`
- `*.battle.net`
- `blizzard.com`
- `*.blizzard.com`
- `battlenet.com`
- `*.battlenet.com`
- `blzstatic.com`
- `*.blzstatic.com`

Flush client DNS cache:

```powershell
ipconfig /flushdns
```

### Verification

- Re-enable Pi-hole blocking.
- Launch Overwatch from Steam.
- Confirm game starts normally.

## Notes

Pi-hole is core DNS infrastructure and should be updated manually rather than through Watchtower automatic updates.

Before making significant Pi-hole DNS changes, create a backup and define a rollback plan.
