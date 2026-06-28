# Unbound

## Purpose

Unbound provides local recursive DNS resolution for the homelab.

Pi-hole forwards upstream DNS queries to Unbound instead of forwarding directly to public DNS providers such as Cloudflare, Google, or Quad9.

## Architecture

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

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Container name:** `unbound`
- **Image:** `mvance/unbound:latest`
- **Deployment method:** Docker Compose via Portainer
- **Docker network:** `media-net`

## Pi-hole Integration

Pi-hole forwards DNS queries to Unbound using:

```text
server=unbound#53
```

This was verified inside the Pi-hole container with:

```bash
docker exec pihole grep -R "server=" /etc/dnsmasq.d /etc/pihole 2>/dev/null
```

Expected line:

```text
/etc/pihole/dnsmasq.conf:server=unbound#53
```

## Health Check

Unbound uses a container health check that queries DNS locally:

```yaml
healthcheck:
  test: ["CMD", "drill", "@127.0.0.1", "cloudflare.com"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Verification Commands

Check container health:

```bash
docker ps --filter name=unbound
```

Test Unbound directly:

```bash
docker exec unbound drill @127.0.0.1 cloudflare.com
```

Expected result:

```text
rcode: NOERROR
```

Test Pi-hole DNS resolution path:

```bash
docker exec pihole nslookup cloudflare.com 127.0.0.1
```

Expected result:

```text
Non-authoritative answer
```

## Audit Result

Unbound and Pi-hole integration was verified successfully.

Confirmed:

- Unbound container is healthy.
- Pi-hole forwards upstream queries to `unbound#53`.
- Pi-hole resolves external domains successfully.
- Unbound resolves external domains directly.

## Notes

Unbound should remain manually updated. Because it is part of DNS infrastructure, automatic updates should be avoided unless there is a tested rollback plan.
