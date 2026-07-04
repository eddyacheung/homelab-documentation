# UGOS Host DNS dnsmasq Forwarding Issue

## Summary

The UGREEN NAS host could not resolve DNS through the local UGOS `dnsmasq` service even though Pi-hole worked normally for other LAN clients.

The root cause was Docker macvlan host isolation. Pi-hole runs with a macvlan LAN IP of `192.168.10.250`, and the UGOS host cannot directly communicate with containers attached to its own macvlan network unless a host-side shim interface exists.

## Environment

- Host: UGREEN DXP4800 Plus running UGOS
- Host LAN IP: `192.168.10.101`
- Pi-hole container LAN IP: `192.168.10.250`
- Host macvlan shim IP: `192.168.10.249/32`
- Primary host interface: `eth0`
- Pi-hole Docker networking:
  - `eth0`: `172.26.0.14/16` on `media-net`
  - `eth1`: `192.168.10.250/24` on macvlan

## Symptoms

From the UGOS host:

```bash
dig google.com @127.0.0.1
dig google.com @192.168.10.250
ping -c 4 192.168.10.250
nc -vz 192.168.10.250 53
```

Observed failures:

```text
communications error to 127.0.0.1#53: timed out
communications error to 192.168.10.250#53: timed out
Destination Host Unreachable
No route to host
```

From a Windows LAN client, Pi-hole worked normally:

```powershell
ping 192.168.10.250
nslookup google.com 192.168.10.250
```

## Investigation

### UGOS dnsmasq was running

`dnsmasq` was listening on localhost:

```bash
sudo ss -lntup | grep ':53'
```

Relevant listeners:

```text
127.0.0.1:53
[::1]:53
```

### UGOS uses vendor dnsmasq config

The normal Debian path was not the active configuration:

```text
/etc/dnsmasq.conf
```

The active UGOS configuration was started with:

```text
--conf-file=/usr/ugreen/etc/dnsmasq/dnsmasq.conf
-7 /usr/ugreen/etc/dnsmasq/dnsmasq.d
```

The active config used:

```text
resolv-file=/usr/ugreen/etc/dnsmasq/dnsmasq-resolv.conf
```

That resolver file correctly pointed to Pi-hole:

```text
nameserver 192.168.10.250
```

### Pi-hole was healthy

Inside the Pi-hole container:

```bash
ss -lntup | grep ':53'
```

Pi-hole was listening on all interfaces:

```text
0.0.0.0:53
[::]:53
```

The Pi-hole container had the expected LAN IP:

```text
192.168.10.250/24 dev eth1
```

### Host routing was normal

The NAS had the expected LAN configuration:

```text
192.168.10.101/24 dev eth0
default via 192.168.10.1 dev eth0
192.168.10.0/24 dev eth0
```

But the ARP table showed:

```text
192.168.10.250 dev eth0 INCOMPLETE
```

This meant the host was asking for the Pi-hole macvlan IP, but the macvlan container could not answer the host directly.

## Root Cause

Docker macvlan isolates the Docker host from containers attached to that macvlan network.

Result:

```text
LAN clients -> Pi-hole macvlan IP: works
UGOS host  -> Pi-hole macvlan IP: fails
```

Because UGOS `dnsmasq` forwards host DNS to `192.168.10.250`, host DNS failed until the host had a route into the macvlan network.

## Temporary Fix

Create a host-side macvlan shim:

```bash
sudo ip link add pihole-shim link eth0 type macvlan mode bridge
sudo ip addr add 192.168.10.249/32 dev pihole-shim
sudo ip link set pihole-shim up
sudo ip route add 192.168.10.250/32 dev pihole-shim
```

Verify:

```bash
ping -c 4 192.168.10.250
dig google.com @192.168.10.250
dig google.com @127.0.0.1
```

Expected result:

```text
0% packet loss
status: NOERROR
SERVER: 192.168.10.250#53
SERVER: 127.0.0.1#53
```

## Persistent Fix

Create the shim script:

```bash
sudo tee /usr/local/sbin/create-pihole-shim.sh >/dev/null <<'EOF'
#!/bin/bash
set -e

IFACE="eth0"
SHIM="pihole-shim"
SHIM_IP="192.168.10.249/32"
PIHOLE_IP="192.168.10.250/32"

ip link show "$SHIM" >/dev/null 2>&1 || \
  ip link add "$SHIM" link "$IFACE" type macvlan mode bridge

ip addr show "$SHIM" | grep -q "192.168.10.249" || \
  ip addr add "$SHIM_IP" dev "$SHIM"

ip link set "$SHIM" up

ip route show "$PIHOLE_IP" | grep -q "$SHIM" || \
  ip route add "$PIHOLE_IP" dev "$SHIM"
EOF

sudo chmod +x /usr/local/sbin/create-pihole-shim.sh
```

Create the systemd service:

```bash
sudo tee /etc/systemd/system/pihole-shim.service >/dev/null <<'EOF'
[Unit]
Description=Create macvlan shim for UGOS host access to Pi-hole
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/create-pihole-shim.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable pihole-shim.service
sudo systemctl start pihole-shim.service
sudo systemctl status pihole-shim.service --no-pager
```

## Post-Reboot Verification

After reboot, verify:

```bash
ip addr show pihole-shim
ip route | grep 192.168.10.250
ping -c 4 192.168.10.250
dig google.com @127.0.0.1
```

Expected output should include:

```text
pihole-shim@eth0
inet 192.168.10.249/32
192.168.10.250 dev pihole-shim scope link
0% packet loss
SERVER: 127.0.0.1#53
status: NOERROR
```

## Rollback

If the shim causes problems:

```bash
sudo systemctl disable --now pihole-shim.service
sudo rm /etc/systemd/system/pihole-shim.service
sudo rm /usr/local/sbin/create-pihole-shim.sh
sudo systemctl daemon-reload
sudo ip route del 192.168.10.250/32 dev pihole-shim 2>/dev/null || true
sudo ip link delete pihole-shim 2>/dev/null || true
```

Then verify DNS or reboot.

## Lessons Learned

- UGOS uses its own dnsmasq configuration under `/usr/ugreen/etc/dnsmasq/`.
- `/etc/dnsmasq.conf` is not the active host DNS configuration.
- Docker macvlan gives Pi-hole a clean LAN IP, but isolates the Docker host from the macvlan container.
- `192.168.10.250 dev eth0 INCOMPLETE` in `ip neigh` was the key clue.
- A `/32` macvlan shim route allows the host to reach only the Pi-hole macvlan IP without changing the rest of LAN routing.

## Related Documentation

- `networking/pihole.md`
- `networking/docker-networking.md`
