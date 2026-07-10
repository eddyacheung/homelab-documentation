# Pi-hole

## Purpose

Provides network-wide DNS filtering and local DNS services.

## Deployment

- Container: `pihole`
- Image: `pihole/pihole:latest`
- Address: `192.168.10.250` on external `pihole_macvlan`
- Persistent data:
  - `/volume1/docker/pihole/etc-pihole:/etc/pihole`
  - `/volume1/docker/pihole/etc-dnsmasq.d:/etc/dnsmasq.d`

## Required variables

Copy `.env.example` to a local `.env` file and set:

```env
PIHOLE_WEBPASSWORD=replace-me
```

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=pihole
docker logs --tail 100 pihole
dig example.com @192.168.10.250
```

Do not commit the real admin password.