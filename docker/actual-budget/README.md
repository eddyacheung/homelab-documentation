# Actual Budget Stack

Self-hosted personal budgeting and account-management service deployed through Portainer on the UGREEN NAS.

## Purpose

Actual Budget provides a private, locally controlled replacement for hosted budgeting applications. The primary database is stored on the NAS, while optional bank synchronization can be added through SimpleFIN.

## Deployment

- Image: `actualbudget/actual-server:latest`
- Container: `actual-budget`
- Local port: `5006`
- Persistent data: `/volume1/docker/actual-budget/data`
- Time zone: `America/Chicago`
- Restart policy: `unless-stopped`

## Access

- Direct LAN endpoint: `http://192.168.10.101:5006`
- Normal browser endpoint: `https://actual.armouredcore.net`

The direct HTTP endpoint is useful only for basic connectivity checks. Actual requires a secure browser context for `SharedArrayBuffer`, so normal use must go through HTTPS.

## Dependencies

- Portainer
- Nginx Proxy Manager
- Cloudflare Tunnel
- Cloudflare DNS for `actual.armouredcore.net`

The service does not require `media-net` or access to media-stack containers.

## Portainer Deployment

1. Create `/volume1/docker/actual-budget/data` on the NAS.
2. In Portainer, create a stack named `actual-budget`.
3. Paste `docker-compose.yml` from this directory.
4. Deploy the stack.
5. Confirm the container reports healthy and review its logs for permission or database errors.

## Verification

```bash
docker ps --filter name=actual-budget
docker logs actual-budget --tail 100
```

The local service should answer on port `5006`.

## Reverse Proxy

Create an Nginx Proxy Manager proxy host with:

- Domain: `actual.armouredcore.net`
- Scheme: `http`
- Forward host: `192.168.10.101`
- Forward port: `5006`
- Block Common Exploits: enabled
- Websockets Support: enabled
- Cache Assets: disabled
- NPM SSL certificate: none, because Cloudflare Tunnel terminates public TLS

Advanced configuration:

```nginx
client_max_body_size 100M;
```

Do not add duplicate `Cross-Origin-Opener-Policy` or `Cross-Origin-Embedder-Policy` headers in NPM. The Actual server supplies them. Duplicate values can prevent cross-origin isolation and produce the fatal `SharedArrayBuffer` error.

## Cloudflare Tunnel

Add a published application route:

```text
actual.armouredcore.net -> http://nginx-proxy-manager:80
```

The browser-facing URL must remain HTTPS.

## SharedArrayBuffer Troubleshooting

Expected response headers:

```text
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

Verify from Windows:

```powershell
curl.exe -I https://actual.armouredcore.net
```

If the headers are present but Firefox still displays the fatal error:

1. Test the site in a Firefox Private Window.
2. If it works privately, clear stored data for `actual.armouredcore.net` or use **Forget About This Site** from Firefox history.
3. Reload the normal tab.

## Security

- Use a strong, unique Actual server password.
- Do not expose port `5006` through the router.
- Cloudflare Access should be added before treating the public hostname as fully hardened.
- Tailscale remains the preferred private remote-access path when public access is unnecessary.
- Enable Actual budget encryption after migration and after confirming backups.
- Never commit SimpleFIN setup tokens, bank credentials, exports, account numbers, or budget databases.

## Backup

Back up the complete persistent-data directory:

```text
/volume1/docker/actual-budget/data
```

Before large imports or migrations, a cold archive can be created:

```bash
docker stop actual-budget
sudo tar -czf /backup/actual-budget-$(date +%F-%H%M).tar.gz \
  -C /volume1/docker/actual-budget data
docker start actual-budget
```

Verify the archive exists and is nonzero before continuing.

## Upgrade

The stack currently tracks `latest`. Upgrades should follow the repository workflow:

1. Review release notes.
2. Back up `/volume1/docker/actual-budget/data`.
3. Pull and redeploy the stack in Portainer.
4. Confirm health, login, sync, and transaction visibility.
5. Roll back to the prior image tag if validation fails.
