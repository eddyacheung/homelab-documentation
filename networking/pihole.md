## Overwatch Fails to Launch Behind Pi-hole

### Symptoms
- Overwatch launched from Steam does not start.
- Disabling Pi-hole immediately resolves the issue.

### Cause
Aggressive Pi-hole blocklists may block Blizzard authentication or CDN domains.

### Resolution
Add the following domains to the Pi-hole allowlist:

- battle.net
- *.battle.net
- blizzard.com
- *.blizzard.com
- battlenet.com
- *.battlenet.com
- blzstatic.com
- *.blzstatic.com

Flush client DNS cache:

ipconfig /flushdns

### Verification
- Re-enable Pi-hole blocking.
- Launch Overwatch from Steam.
- Confirm game starts normally.
