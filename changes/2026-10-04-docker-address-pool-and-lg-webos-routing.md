# Docker Address-Pool and LG webOS Routing Fix

**Date:** 2026-10-04

## Summary

Home Assistant showed the LG C9 as off even while the television was powered on. Home Assistant could not switch inputs, including the existing HDMI 3 PC action exposed through Apple Home.

The problem was not the LG webOS integration, Apple Home, Wi-Fi signal, or UniFi IoT isolation. The UGREEN NAS had an overlapping Docker route that captured traffic intended for the IoT VLAN.

## Symptoms

- LG C9 was powered on but Home Assistant reported the media player as `off`.
- `media_player.select_source` failed because Home Assistant believed the device was off.
- Reloading the LG webOS integration did not restore control.
- A Windows client on `192.168.10.100` could ping `192.168.20.249` and connect to TCP port 3000.
- The UGREEN NAS could not reach the TV.

Broken NAS tests:

```text
From 192.168.16.1 Destination Host Unreachable
nc: connect to 192.168.20.249 port 3000 failed: No route to host
```

## Root Cause

Docker Compose had automatically created:

```text
Network: 56_default
Subnet:  192.168.16.0/20
Gateway: 192.168.16.1
```

The `192.168.16.0/20` subnet includes `192.168.20.0/24`, which is the real IoT VLAN.

Linux therefore selected:

```text
192.168.20.249 dev br-46f18cf90822 src 192.168.16.1
```

instead of routing through UniFi.

The network had been created on 2026-10-03 and had no attached containers during troubleshooting.

## Recovery

After the stale/conflicting Docker network disappeared, the route immediately returned to:

```text
192.168.20.249 via 192.168.10.1 dev eth0 src 192.168.10.101
```

Validation from the UGREEN NAS:

```text
ping: 4 transmitted, 4 received, 0% packet loss
TCP 192.168.20.249:3000: succeeded
```

Reloading the Home Assistant LG webOS integration then restored the correct TV state and local control.

UniFi IoT network isolation remained enabled.

## Permanent Prevention

Updated `/etc/docker/daemon.json`:

```json
{
  "data-root": "/volume1/@docker",
  "features": {
    "containerd-snapshotter": false
  },
  "default-address-pools": [
    {
      "base": "10.200.0.0/16",
      "size": 24
    }
  ]
}
```

This reserves `10.200.0.0/16` for future automatically generated Docker networks and causes Docker to allocate `/24` subnets from that pool.

The configuration was validated with:

```bash
dockerd --validate --config-file=/etc/docker/daemon.json
```

Result:

```text
configuration OK
```

Docker was restarted and all service containers returned. Homarr used `restart=on-failure`, so it was started manually after the clean daemon restart.

A temporary network verified the new allocator:

```text
docker-pool-test -> 10.200.1.0/24
```

The test network was then removed.

## Notes

- Existing Docker networks were intentionally left unchanged.
- `portainer_portainer_default` remains on `192.168.32.0/20`; it does not currently overlap the active LAN or IoT VLAN.
- New automatically allocated Docker networks should now remain inside `10.200.0.0/16`.
- Before creating future physical VLANs, check both Docker networks and host routes for overlap.

## Verification Commands

```bash
docker network inspect $(docker network ls -q) \
  --format '{{.Name}} {{range .IPAM.Config}}{{.Subnet}} {{end}}' | sort

ip route get 192.168.20.249
nc -vz 192.168.20.249 3000
dockerd --validate --config-file=/etc/docker/daemon.json
```
