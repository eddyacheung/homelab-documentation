# Open WebUI

## Purpose

Provides the browser interface for locally hosted AI models served by Ollama.

## Deployment

- Container: `open-webui`
- Image: `ghcr.io/open-webui/open-webui:main`
- Published port: `3002:8080`
- Ollama endpoint: `http://192.168.10.100:11434`
- Network: external `ai-net`
- Persistent data: `/volume1/docker/open-webui:/app/backend/data`
- Watchtower: opted in

## Deploy

```bash
docker compose up -d
```

## Verify

```bash
docker ps --filter name=open-webui
docker logs --tail 100 open-webui
curl -I http://127.0.0.1:3002
```

Back up the persistent data directory before rebuilding the service.