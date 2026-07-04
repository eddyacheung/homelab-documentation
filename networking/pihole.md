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

## Docker Networking

Pi-hole uses a Docker macvlan address so it can live on the LAN as its own DNS server:

```text
Pi-hole LAN IP: 192.168.10.250
```

The Pi-hole container is also attached to the Docker bridge used by homelab services:

```text
media-net IP: 172.26.0.14
```

Important macvlan behavior:

- LAN clients can reach `192.168.10.250` normally.
- The UGREEN NAS host cannot directly reach its own macvlan container by default.
- UGOS `dnsmasq` forwards host DNS to Pi-hole.
- Without a host-side macvlan shim, host DNS queries to Pi-hole time out.

The persistent host shim is:

```text
Interface: pihole-shim
Shim IP:   192.168.10.249/32
Route:     192.168.10.250/32 dev pihole-shim
Service:   pihole-shim.service
```

Detailed investigation and fix:

```text
troubleshooting/ugos-host-dnsmasq-forwarding.md
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

Verify LAN clients can reach Pi-hole:

```powershell
ping 192.168.10.250
nslookup google.com 192.168.10.250
```

Verify the UGOS host can reach Pi-hole through the macvlan shim:

```bash
ip addr show pihole-shim
ip route | grep 192.168.10.250
ping -c 4 192.168.10.250
dig google.com @127.0.0.1
```

Expected result:

```text
pihole-shim@eth0
192.168.10.250 dev pihole-shim scope link
0% packet loss
SERVER: 127.0.0.1#53
status: NOERROR
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

## UGOS Host DNS Forwarding Fix

Fix completed on 2026-07-04.

Confirmed:

- UGOS uses `/usr/ugreen/etc/dnsmasq/dnsmasq.conf` for host DNS forwarding.
- UGOS `dnsmasq` forwards to Pi-hole at `192.168.10.250`.
- The NAS host could not reach `192.168.10.250` because Pi-hole uses Docker macvlan.
- `ip neigh` showed `192.168.10.250 dev eth0 INCOMPLETE` before the fix.
- Creating `pihole-shim` restored host-to-Pi-hole connectivity.
- `dig google.com @127.0.0.1` now succeeds from the UGOS host.

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
