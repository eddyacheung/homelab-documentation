# Cloudflare Zero Trust

## Purpose

Cloudflare Zero Trust provides secure remote access to selected homelab services without exposing the home network through router port forwarding.

Benefits:

- No inbound firewall or router port forwarding required
- Cloudflare-managed public TLS
- Google OAuth authentication through Cloudflare Access
- Home public IP address remains hidden
- Per-application access policies
- Reusable authentication pattern for future services

## Architecture

```text
Internet
    |
    v
Cloudflare Edge
    |
    v
Cloudflare Access
    |
    v
Google OAuth
    |
    v
Cloudflare Tunnel
    |
    v
Nginx Proxy Manager
    |
    v
Internal Docker Services
```

Cloudflare handles public DNS, HTTPS, and identity-aware access control.

Cloudflared runs inside the homelab as an outbound connector. It does not require inbound ports to be opened on the router.

Nginx Proxy Manager remains the internal reverse proxy and sends traffic to the correct Docker service.

## Domain

Primary domain:

```text
armouredcore.net
```

## Tunnel

| Setting | Value |
|---|---|
| Tunnel name | `homelab` |
| Connector | `cloudflared` |
| Deployment method | Portainer Stack |
| Status | Healthy |
| Docker network | `media-net` |

The tunnel is deployed as a Docker container through Portainer rather than a one-off `docker run` command.

## Cloudflared Stack

The tunnel token is secret and should not be committed to GitHub.

Example stack shape:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token <TUNNEL_TOKEN>
    networks:
      - media-net

networks:
  media-net:
    external: true
```

## Published Applications

### Seerr

Public URL:

```text
https://seerr.armouredcore.net
```

Cloudflare published application route:

| Setting | Value |
|---|---|
| Subdomain | `seerr` |
| Domain | `armouredcore.net` |
| Service type | HTTP |
| Service URL | `nginx-proxy-manager:80` |

Nginx Proxy Manager proxy host:

| Setting | Value |
|---|---|
| Domain | `seerr.armouredcore.net` |
| Scheme | `http` |
| Forward Hostname/IP | `seerr` |
| Forward Port | `5055` |
| Block Common Exploits | Enabled |
| Websockets Support | Enabled |
| SSL in NPM | Disabled for now |

Cloudflare provides HTTPS externally. The Cloudflare Tunnel to Nginx Proxy Manager and the NPM to Seerr hop remain internal to Docker networking.

## Authentication

Configured identity providers:

- Google OAuth
- One-time PIN default login method

The Seerr Access application is configured to use Google OAuth.

Authentication flow:

```text
User
  -> Cloudflare Access
  -> Google Sign-In
  -> Cloudflare Tunnel
  -> Nginx Proxy Manager
  -> Seerr login
```

This creates two layers of authentication:

1. Cloudflare Access with Google authentication
2. Seerr application login

## Google OAuth

A Google Cloud project was created for Cloudflare Access authentication.

Project name:

```text
Cloudflare Zero Trust
```

Google OAuth client type:

```text
Web application
```

Cloudflare values:

| Field | Value |
|---|---|
| Team domain | `armouredcore.cloudflareaccess.com` |
| Authorized redirect URI | `https://armouredcore.cloudflareaccess.com/cdn-cgi/access/callback` |
| Authorized JavaScript origins | Not required |

The Google client ID and client secret are stored in Cloudflare and should not be committed to GitHub.

The OAuth app was moved to production to avoid test-user restrictions.

## Access Policy

Seerr uses the following Cloudflare Access policy:

| Setting | Value |
|---|---|
| Policy name | `Allow Eddy` |
| Action | Allow |
| Rule type | Email |
| Allowed email | `eddyacheung@gmail.com` |
| Session duration | 24 hours |
| Identity provider | Google |

## Validation

Validated behavior:

1. Browse to `https://seerr.armouredcore.net` in a private browser window.
2. Browser redirects to Google sign-in for Cloudflare Access.
3. Sign in with `eddyacheung@gmail.com`.
4. Cloudflare Access allows the request.
5. Browser reaches the Seerr login page.

Successful validation confirms:

- Cloudflare DNS is working
- Cloudflare Tunnel is healthy
- Google OAuth is configured correctly
- Cloudflare Access policy is enforced
- Nginx Proxy Manager routes public hostname traffic to Seerr

## Security Notes

- Do not commit the Cloudflare tunnel token.
- Do not commit Google OAuth client secrets.
- Do not expose Portainer, Pi-hole, qBittorrent, or Nginx Proxy Manager publicly without Cloudflare Access.
- Prefer Cloudflare Access for any public homelab application.
- Keep local `.home` names for LAN-only convenience.
- Use Tailscale or local access for sensitive administrative services when possible.

## Backup and Recovery

### Backup

Important configuration lives in:

- Cloudflare Zero Trust tunnel configuration
- Cloudflare published application routes
- Cloudflare Access applications and policies
- Google OAuth client configuration
- Portainer `cloudflared` stack configuration
- Nginx Proxy Manager proxy hosts

### Recovery

If public access breaks:

1. Confirm local `.home` access still works.
2. Check the `cloudflared` container in Portainer.
3. Verify the tunnel status is Healthy in Cloudflare.
4. Verify the published application route points to `nginx-proxy-manager:80`.
5. Verify the NPM proxy host points to the correct backend container and port.
6. Temporarily disable or adjust the Access policy only if authentication is the failure point.

If the tunnel token is compromised:

1. Rotate or recreate the tunnel token in Cloudflare.
2. Update the Portainer stack with the new token.
3. Redeploy the stack.
4. Verify the tunnel returns to Healthy.

## Procedure for Adding a Protected Service

1. Confirm the service is reachable locally.
2. Confirm the service container and NPM share a Docker network.
3. Add or confirm an NPM proxy host for the public hostname.
4. Add a Cloudflare published application route pointing to `nginx-proxy-manager:80`.
5. Create a Cloudflare Access application for the public hostname.
6. Select Google as the identity provider.
7. Attach an allow policy for the approved user or group.
8. Test in a private browser window.
9. Document the hostname, route, access policy, and validation result.

## Future Services

Candidate services to protect next:

- Portainer
- Nginx Proxy Manager
- Home Assistant
- Open WebUI
- Homarr
- Uptime Kuma

Administrative services should be reviewed carefully before being made reachable from the public Internet, even behind Cloudflare Access.
