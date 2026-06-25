# Unbound Recursive DNS

## Overview
Unbound provides recursive DNS resolution for Pi-hole, reducing reliance on third-party public DNS resolvers.

## Architecture

LAN clients
  → Pi-hole (192.168.10.250, pihole_macvlan)
    → Unbound (media-net only)
      → DNS root and authoritative servers

## Deployment
Deployed as a Portainer stack
Image: mvance/unbound:latest
Network: media-net
No host ports published

## Pi-hole Integration

Pi-hole is attached to:

pihole_macvlan for its LAN-facing DNS address
media-net for private communication with Unbound

Pi-hole custom upstream DNS:

unbound#53

## Validation

From the Pi-hole container:

dig @unbound cloudflare.com
dig @127.0.0.1 google.com


## Availability Considerations
Pi-hole and Unbound run on the NAS. If the NAS is unavailable, clients using Pi-hole as their only DNS server cannot resolve domain names even if the internet connection is otherwise available.

A future improvement is a second Pi-hole + Unbound instance on independent hardware for DNS redundancy.
