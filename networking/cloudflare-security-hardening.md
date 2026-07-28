# Cloudflare Security Hardening

**Completed:** 2026-07-27

## Scope

This document records the Cloudflare security controls applied to the public services hosted under `armouredcore.net`.

Public applications currently exposed through Cloudflare Tunnel:

- `actual.armouredcore.net`
- `ha.armouredcore.net`
- `seerr.armouredcore.net`

Administrative interfaces such as Portainer, Nginx Proxy Manager, Grafana, and Uptime Kuma remain private and are not published through the tunnel.

## Security Architecture

```text
Internet
  |
  v
Cloudflare DNS and edge
  |- DDoS protection
  |- Cloudflare managed ruleset
  |- Bot Fight Mode
  |- Custom WAF rules
  |- Cloudflare Access for Actual Budget
  |
  v
Cloudflare Tunnel
  |
  v
Nginx Proxy Manager
  |
  v
Self-hosted application
```

No inbound router port forwarding is required for these services.

## Cloudflare Access: Actual Budget

`actual.armouredcore.net` is protected by a self-hosted Cloudflare Access application.

Reusable policy:

- **Policy:** `Allow Eddy`
- **Action:** Allow
- **Include:** `eddyacheung@gmail.com`
- **Require:** Google login method
- **Session duration:** 24 hours

Authentication chain:

```text
Cloudflare Access
  -> Google authentication
  -> Actual server password
  -> Actual budget encryption password
```

An older unused `Allow Eddy` policy with no attached applications was identified for removal.

## Bot Fight Mode

Bot Fight Mode is enabled for the `armouredcore.net` zone.

Current settings:

- Bot Fight Mode: On
- JavaScript detections: On
- Challenge passage: 30 minutes

Validation was performed through Cloudflare Security Analytics. Cloudflare issued a Managed Challenge to a Recorded Future Global Inventory Crawler request against `actual.armouredcore.net`, confirming that bot mitigation is active.

## Cloudflare Managed Ruleset

The Cloudflare managed ruleset is enabled and always active for the zone.

This provides edge filtering for common web application exploits and malicious request patterns before requests reach the tunnel or origin services.

## Custom WAF Rules

### 1. Block Common Exploit Paths

**Action:** Block  
**Execution order:** First

Matched paths:

- `/.env`
- `/.git`
- `/phpmyadmin`
- `/wp-admin`
- `/wp-login.php`
- `/xmlrpc.php`
- `/vendor/`
- `/composer.json`
- `/composer.lock`

The rule uses OR logic so a request matching any listed path is blocked.

### 2. Block Backup Files

**Action:** Block  
**Execution order:** Immediately after `Block Common Exploit Paths`

Blocked file suffixes:

- `.bak`
- `.old`
- `.backup`
- `.zip`
- `.sql`
- `.tar`
- `.gz`
- `.tgz`

This reduces the chance of accidentally exposing database dumps, archives, or stale backup files.

## Rate Limiting Decision

Cloudflare Free plan rate limiting was evaluated but not deployed.

Available controls were limited to:

- 10-second counting period
- Block action only
- 10-second mitigation duration

A broad rate limit could block legitimate bursts from the Home Assistant companion app or normal Seerr page loads. Home Assistant and Seerr therefore retain native authentication without an additional Cloudflare rate-limit rule.

## Application-Specific Decisions

### Home Assistant

Cloudflare Access was not added because the companion app requires reliable background API, token, WebSocket, notification, presence, and sensor traffic.

Current protection:

- Cloudflare Tunnel
- Cloudflare managed ruleset
- Bot Fight Mode
- Custom WAF rules
- Home Assistant MFA
- Strong unique password
- No inbound port forwarding

### Seerr

Cloudflare Access was not added because the service is intended for future friends and family access through Seerr and Plex authentication.

Current protection:

- Cloudflare Tunnel
- Cloudflare managed ruleset
- Bot Fight Mode
- Custom WAF rules
- Native Seerr/Plex authentication
- No inbound port forwarding

### Actual Budget

Actual remains behind Cloudflare Access because it is browser-based, private, and contains financial data.

## Validation

Cloudflare analytics were reviewed after enabling the controls.

Observed over the sampled 24-hour period:

- 859 total requests
- 0 cached requests
- 859 uncached requests
- 15 unique visitors
- Maximum of 5 unique visitors in one hour

No recurring attack pattern requiring an additional custom rule was identified.

Zero cached requests is expected because Home Assistant, Seerr, and Actual Budget are dynamic authenticated applications and should not be cached as public static content.

## Operational Checklist

Periodically review:

1. **Security -> Analytics -> Events** for blocked or challenged requests.
2. Repeated probes against one hostname or path.
3. Unexpected authentication failures in Home Assistant or Seerr.
4. Cloudflare Tunnel health and published routes.
5. Application and container update status.
6. Backup success and restore readiness.

Add another custom rule only when analytics show a repeatable pattern that is not already handled by Bot Fight Mode or the managed ruleset.

## Future Public Services

If administrative applications are ever published, protect them with Cloudflare Access rather than exposing native login pages directly.

Examples:

- Portainer
- Nginx Proxy Manager
- Grafana
- Uptime Kuma

Home Assistant and Seerr should continue using their current application-specific security models unless compatibility requirements change.
